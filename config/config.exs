use Mix.Config

# Configure the database and application repo
config :plenario, Plenario.Repo, types: Plenario.PostGISTypes

config :plenario, ecto_repos: [Plenario.Repo]


# Configures the endpoint
config :plenario, PlenarioWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "jCp/RnOfjaRob73dORfNI9QvsP5719peAhXoo6SP2N41Kw+5Ofq9N0Zu6cyzqGI4",
  render_errors: [view: PlenarioWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Plenario.PubSub, adapter: Phoenix.PubSub.PG2]


# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]


# Configure s3 buckets
config :plenario, :s3_export_bucket, "plenario_exports_#{Mix.env()}"

config :plenario, :s3_export_ttl, days: 5


# configure quantum scheduler
config :plenario, :refresh_offest, minutes: 1

config :plenario, Plenario.Scheduler,
  global: true,
  jobs: [
    # run the find refreshable metas every minute (offset is 1 minute above)
    {"* * * * *", {Plenario.Etl.ScheduledJobs, :find_refreshable_metas, []}}
  ]


# configure canary
config :canary,
  repo: Plenario.Repo,
  unauthorized_handler: {PlenarioAuth.ErrorHandler, :handle_unauthorized},
  not_found_handler: {PlenarioAuth.ErrorHandler, :handle_not_found}


# configure bamboo (email)
config :plenario, Plenario.Mailer, adapter: Bamboo.LocalAdapter
config :plenario, :email_sender, "plenario@uchicago.edu"
config :plenario, :email_subject, "Plenario Notification"


# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
