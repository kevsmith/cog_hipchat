defmodule CogHipChat.Provider do

  require Logger

  use GenServer
  use CogChat.Provider

  alias Carrier.Connection
  alias Carrier.GenMqtt
  alias CogHipChat

  defstruct [:token, :jabber_id, :jabber_password, :nickname, :mbus, :xmpp, :incoming]

  def display_name, do: "HipChat"

  def valid_config?() do
    config = Application.get_all_env(:cog_hipchat)
    Keyword.get(config, :api_root) != nil and
    Keyword.get(config, :chat_host) != nil and
    Keyword.get(config, :conf_host) != nil and
    Keyword.get(config, :api_token) != nil and
    Keyword.get(config, :jabber_id) != nil and
    Keyword.get(config, :jabber_password) != nil and
    Keyword.get(config, :incoming_topic) != nil
  end

  def lookup_user(handle) do
    if String.match?(handle, ~r/.+@.+/) do
      GenServer.call(__MODULE__, {:call_connector, {:lookup_user_jid, handle}}, :infinity)
    else
      GenServer.call(__MODULE__, {:call_connector, {:lookup_user_handle, handle}}, :infinity)
    end
  end

  def lookup_room({:name, name}) do
    case GenServer.call(__MODULE__, {:call_connector, {:lookup_room_name, name}}, :infinity) do
      {:error, :not_found} ->
        # This might be a redirect so let's try looking up the "room"
        # as a user
        case lookup_user(name) do
          {:ok, user} ->
            {:ok, %Room{id: user.id,
                        is_dm: true,
                        provider: "hipchat",
                        name: "direct"}}
          error ->
            error
        end
      result ->
        result
    end
  end
  def lookup_room({:id, id}) do
      GenServer.call(__MODULE__, {:call_connector, {:lookup_room_jid, id}}, :infinity)
  end

  def list_joined_rooms() do
    GenServer.call(__MODULE__, {:call_connector, :list_joined_rooms}, :infinity)
  end

  def send_message(target, message) do
    GenServer.call(__MODULE__, {:call_connector, {:send_message, target, message}}, :infinity)
  end

  def start_link(args \\ []) do
    case Application.ensure_all_started(:romeo) do
      {:ok, _} ->
        GenServer.start_link(__MODULE__, args, name: __MODULE__)
      error ->
        error
    end
  end

  def init(_) do
    config = Application.get_all_env(:cog_hipchat)
    incoming = Keyword.fetch!(config, :incoming_topic)
    case CogHipChat.Connector.start_link(config) do
      {:ok, xmpp_conn} ->
        {:ok, mbus} = Connection.connect()
        {:ok, %__MODULE__{incoming: incoming, mbus: mbus, xmpp: xmpp_conn}}
      error ->
        error
    end
  end

  def handle_call({:call_connector, connector_message}, _from, state) do
    {:reply, GenServer.call(state.xmpp, connector_message, :infinity), state}
  end

  def handle_cast({:chat_event, event}, state) do
    GenMqtt.cast(state.mbus, state.incoming, "event", event)
    {:noreply, state}
  end
  def handle_cast({:chat_message, msg}, state) do
    GenMqtt.cast(state.mbus, state.incoming, "message", msg)
    {:noreply, state}
  end

end
