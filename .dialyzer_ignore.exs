[
  ~r/Mix.Task behaviour is not available/,
  {"lib/algora/contracts/contracts.ex", :pattern_match},
  # ExUnit is not available in the PLT when running dialyzer with MIX_ENV=dev
  {"test/support/conn_case.ex", :unknown_function},
  {"test/support/data_case.ex", :unknown_function},
  # Money.Ecto.Composite.Type.t/0 is defined but not exported for dialyzer
  {"lib/algora/jobs/schemas/job_posting.ex", :unknown_type}
]
