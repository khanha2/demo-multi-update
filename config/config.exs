import Config

config :demo_multi_update, DemoMultiUpdate.Repo,
  pool_size: 10,
  queue_target: 1_000,
  queue_interval: 5_000,
  timeout: 60_000,
  priv: "priv/repo"

config :demo_multi_update, ecto_repos: [DemoMultiUpdate.Repo]

config :logger, level: :info
