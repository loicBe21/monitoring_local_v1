defmodule PmLogin.SaisieTemps.TimeEntriesValidee do

  use Ecto.Schema

  import Ecto.Changeset
  alias PmLogin.Login.User

  schema "time_entries_validee" do
    field :date, :date
    field :time_value, :decimal
   # field :validation_status , :integer
    belongs_to :user, User
    belongs_to :user_validator , User


    timestamps()
  end

  @doc false
  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:date, :time_value, :user_id, :user_validator_id])
    |> validate_required([:date, :time_value, :user_id, :user_validator_id])
    |> validate_number(:time_value, greater_than_or_equal_to: 0) # Assurez-vous que time_value est un nombre positif
  end


  def create_changeset(entri_validee , attrs) do
    entri_validee
    |>cast(attrs ,[:date , :time_value ,:user_id , :user_validator_id ] )
    |> validate_required([:date, :time_value, :user_id, :user_validator_id ])
    |> validate_number(:time_value, greater_than_or_equal_to: 0) # Assurez-vous que time_value est un nombre positif
  end


end
