defmodule Algora.Activities.Views do
  @moduledoc false
  alias Algora.Activities.Activity

  require Algora.Activities.Activity
  require EEx

  @base_path Path.join([File.cwd!(), "lib", "algora", "activities", "views"])

  def render(activity, kind) when kind in ~w(title txt)a do
    apply(__MODULE__, :"#{activity.type}_#{kind}", [activity, activity.assoc])
  end

  Enum.each(Activity.types(), fn type ->
    base_type = type |> to_string() |> String.split("_") |> List.first() |> String.to_atom()
    EEx.function_from_file(:def, :"#{type}_title", Path.join(@base_path, "#{type}.title.eex"), [:activity, base_type])
    EEx.function_from_file(:def, :"#{type}_txt", Path.join(@base_path, "#{type}.txt.eex"), [:activity, base_type])
  end)
end
