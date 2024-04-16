defmodule PmLogin.SaisieTemps.TimeEntrie do

  use Ecto.Schema
  import Ecto.Changeset
  alias PmLogin.Monitoring.Task
  alias PmLogin.Login.User
  alias PmLogin.Monitoring.Project

  schema "time_entries" do

    field :date_entries, :naive_datetime
    belongs_to :task, Task
    belongs_to :user, User
    belongs_to :project, Project
    field :libele, :string
    field :time_value, :decimal
   # field :validation_status , :integer
    timestamps()

  end

  def   changeset(time_entries , attrs) do
    time_entries
      |> cast(attrs , [:date_entries , :task_id ,:user_id ,:project_id ,:libele  , :time_value])
      |>validate_required(:date_entries ,  message: "date_entries required")
      |>validate_required(:task_id , message: "task can't be null")
      |>validate_required(:user_id , message: "user can't be null")
      |>validate_required(:project_id , message: "project can't be null")
      |>validate_required(:libele , message: "libele can't be null")
      |>validate_required(:time_value , message: "time value can't be null")
      |> validate_positive_time_value

  end

 def update_changeset(entrie ,attrs) do
  entrie
   |>cast(attrs , [:id , :task_id ,:user_id ,:project_id ,:libele  , :time_value])
      |>validate_required(:task_id , message: "task can't be null")
      |>validate_required(:user_id , message: "user can't be null")
      |>validate_required(:project_id , message: "project can't be null")
      |>validate_required(:libele , message: "libele can't be null")
      |>validate_required(:time_value , message: "time value can't be null")
      |>validate_positive_time_value()
 end

  defp validate_date(changeset) do
    date = get_field(changeset, :date_entries)
    now = NaiveDateTime.utc_now()
    case Date.compare(now, date) do
      :lt ->
        changeset
        |>add_error(:date_entries , "veuillez verifier la date")

      _ -> changeset
    end
  end


  defp validate_positive_time_value(changeset) do
    time_value = get_field(changeset, :time_value)
    case Decimal.cmp(time_value, Decimal.new(0)) do
      :lt ->
        changeset
        |> add_error(:time_value, "veuillez entrer une valeur positive pour le temps")
      _ ->
        changeset
    end
  end


  defp validate_positive_time_value(changeset) do
    case get_field(changeset, :time_value) do
      nil -> add_error(changeset, :time_value, "time value can't be null")
      value when value > 0 -> changeset
      _ -> add_error(changeset, :time_value, "time value must be greater than 0")
    end
  end


  #changeset de validation d'une ligne de saisie
 # def validation_changeset(entrie , attrs) do
 #  entrie
 #   |>cast(attrs , [:validation_status] )


 # end




end
