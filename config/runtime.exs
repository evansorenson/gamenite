import Config

defmodule ConfigParser do
  def parse_stun_servers(""), do: []

  def parse_stun_servers(servers) do
    servers
    |> String.split(",")
    |> Enum.map(fn server ->
      with [addr, port] <- String.split(server, ":"),
           {port, ""} <- Integer.parse(port) do
        %{server_addr: parse_addr(addr), server_port: port}
      else
        _ -> raise("Bad STUN server format. Expected addr:port, got: #{inspect(server)}")
      end
    end)
  end

  def parse_turn_servers(""), do: []

  def parse_turn_servers(servers) do
    servers
    |> String.split(",")
    |> Enum.map(fn server ->
      with [addr, port, username, password, proto] when proto in ["udp", "tcp", "tls"] <-
             String.split(server, ":"),
           {port, ""} <- Integer.parse(port) do
        %{
          server_addr: parse_addr(addr),
          server_port: port,
          username: username,
          password: password,
          relay_type: String.to_atom(proto)
        }
      else
        _ ->
          raise("""
          "Bad TURN server format. Expected addr:port:username:password:proto, got: \
          #{inspect(server)}
          """)
      end
    end)
  end

  def parse_integrated_turn_ip(ip) do
    with {:ok, parsed_ip} <- ip |> to_charlist() |> :inet.parse_address() do
      parsed_ip
    else
      _ ->
        raise("""
        Bad integrated TURN IP format. Expected IPv4, got: \
        #{inspect(ip)}
        """)
    end
  end

  def parse_use_integrated_turn("true"), do: true
  def parse_use_integrated_turn("false"), do: false

  def parse_use_integrated_turn(env) do
    raise("""
    Bad USE_INTEGRATED_TURN enviroment variable value. Expected "true" or "false", got: \
    #{inspect(env)}
    """)
  end

  def parse_addr(addr) do
    case :inet.parse_address(String.to_charlist(addr)) do
      {:ok, ip} -> ip
      # FQDN?
      {:error, :einval} -> addr
    end
  end
end

config :rooms,
  roommate_colors: [
    "#222222",
    "#F3C300",
    "#875692",
    "#F38400",
    "#A1CAF1",
    "#BE0032",
    "#C2B280",
    "#848482",
    "#008856",
    "#E68FAC",
    "#0067A5",
    "#F99379",
    "#604E97",
    "#F6A600",
    "#B3446C",
    "#DCD300",
    "#882D17",
    "#8DB600",
    "#654522",
    "#E25822",
    "#2B3D26"
  ],
  stun_servers:
    System.get_env("STUN_SERVERS", "64.233.163.127:19302") |> ConfigParser.parse_stun_servers(),
  turn_servers: System.get_env("TURN_SERVERS", "") |> ConfigParser.parse_turn_servers(),
  use_integrated_turn:
    System.get_env("USE_INTEGRATED_TURN", "false") |> ConfigParser.parse_use_integrated_turn(),
  integrated_turn_ip:
    System.get_env("INTEGRATED_TURN_IP", "127.0.0.1") |> ConfigParser.parse_integrated_turn_ip()

# protocol = if System.get_env("USE_TLS") == "true", do: :https, else: :http

# get_env = fn env, default ->
#   if config_env() == :prod do
#     System.fetch_env!(env)
#   else
#     System.get_env(env, default)
#   end
# end

# host = get_env.("VIRTUAL_HOST", "localhost")

# args =
#   if protocol == :https do
#     [
#       keyfile: get_env.("KEY_FILE_PATH", "priv/certs/key.pem"),
#       certfile: get_env.("CERT_FILE_PATH", "priv/certs/certificate.pem"),
#       cipher_suite: :strong
#     ]
#   else
#     []
#   end
#   |> Keyword.merge(otp_app: :gamenite_web, port: port)

# config :gamenite_web, GameniteWeb.Endpoint, [
#   {:url, [host: host]},
#   {protocol, args}
# ]

if config_env() == :prod do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  app_name =
    System.get_env("FLY_APP_NAME") ||
      raise "FLY_APP_NAME not available"

  config :gamenite_web, GameniteWeb.Endpoint,
    server: true,
    url: [host: "#{app_name}.fly.dev", port: 80],
    http: [
      port: String.to_integer(System.get_env("PORT") || "4000"),
      # IMPORTANT: support IPv6 addresses
      transport_options: [socket_opts: [:inet6]]
    ],
    secret_key_base: secret_key_base

  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  config :gamenite_persistance, GamenitePersistance.Repo,
    url: database_url,
    # IMPORTANT: Or it won't find the DB server
    socket_options: [:inet6],
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")
end
