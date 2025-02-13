defmodule Algora.Repo.Migrations.DefineNegateOperator do
  use Ecto.Migration

  def up do
    execute("""
    CREATE OR REPLACE FUNCTION money_negate(money_1 money_with_currency)
    RETURNS money_with_currency
    IMMUTABLE
    STRICT
    LANGUAGE plpgsql
    AS $$
        DECLARE
        currency varchar;
        addition numeric;
        BEGIN
        currency := currency_code(money_1);
        addition := amount(money_1) * -1;
        return row(currency, addition);
        END;
    $$;
    """)
    |> Money.Migration.adjust_for_type(repo())

    execute("""
    CREATE OPERATOR - (
        rightarg = money_with_currency,
        procedure = money_negate
    );
    """)
    |> Money.Migration.adjust_for_type(repo())
  end

  def down do
    execute("DROP OPERATOR IF EXISTS - (none, money_with_currency);")

    execute("DROP FUNCTION IF EXISTS money_negate(money_with_currency);")
  end
end
