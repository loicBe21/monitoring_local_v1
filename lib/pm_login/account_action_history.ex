defmodule PmLogin.AccountActionHistory do

  alias PmLogin.Login



  def create_change_messages(old_user, field_changed) do
    Enum.map(field_changed, fn {field, new_value} ->
      old_value = Map.get(old_user, field)
      change_message(old_value, new_value, field)
    end)
  end

  # Fonction pour générer un message d'historique pour un champ modifié
  defp change_message(old_value, new_value, field) do
    case field do
      right_id ->
        old_right = Login.get_right!(old_value)
        new_right = Login.get_right!(new_value)
        "Le  droit de l'utilisateur a été modifié de #{old_right.title} à #{new_right.title}."
    end

  end







end
