defmodule PmLogin.SaisieTemps do

  #module doc
  #Contexte de tout les models dans le dossier lib/pmLogin/saisie_temps
  #author loicRavelo05@gmail.com


  import Decimal
  import Ecto.Query, warn: false
  alias Hex.API.User
  alias PmLogin.Monitoring
  alias PmLogin.Utilities
  alias PmLogin.SqlUtilities
  alias PmLogin.SaisieTemps.TimeEntrie
  alias PmLogin.Repo
  alias PmLogin.Login
  alias PmLogin.SaisieTemps.TimeEntriesValidee
  alias PmLogin.Login.User




  #pour test changeset
  #PmLogin.SaisieTemps.test_changeset()
  def test_changeset() do
    attrs = %{task_id: 555, user_id: 888 ,project_id: 555 ,date_entries: NaiveDateTime.utc_now ,libele: "test" , time_value: 0.5 }
    TimeEntrie.changeset(%TimeEntrie{} , attrs)
  end



  #method de validation du tache et du projet entreer dans une changeset
  def validate_task_and_project(changeset) do
    #verifie si la tache et le projet existe dans la base de donnees
    case {Monitoring.get_task_with_card!(changeset.changes.task_id), Monitoring.get_project!(changeset.changes.project_id)} do
        {task, project} when is_map(task) and is_map(project) ->
          #verification si la tache et le projet ont une lien (project_id foreign keys)
          if task.project_id == project.id do
            #retourne la changeset valid et la tache , utiliser pour une seconde validation
            {:ok ,changeset , task }
          else
            {:error , "La tâche spécifiée n'est pas associée au projet spécifié."}
          end

        {nil, _} ->

           {:error ,  "La tâche spécifiée n'existe pas."}
        {_, nil} ->
          {:error , "Le projet spécifié n'existe pas."}

    end
  end


  #method qui sauvgarde les ligne de saisie dans la pase de doneees
  #attrs : Map des attribut requis pour TimeEntries
  def save_entries(attrs) do
    #creation d une changeset
    changeset =   TimeEntrie.changeset(%TimeEntrie{} , attrs)
    #verification du changeset
    case changeset.valid? do
      true ->
        case  validate_task_and_project(changeset) do
          {:ok , _ , task} ->

            if task.status_id == 1 do
              Repo.insert(changeset)
              Monitoring.put_task_to_ongoing(task,changeset.changes.user_id)
              {:ok , changeset}

            else
              Repo.insert(changeset)
              {:ok , changeset}
            end
          {:error , message} ->
            {:error , message}

        end
      false ->
        {:error , "une erreur dans les donnes entrees"}
    end
  end


  #methode modif saisie
  def update_entrie(entrie,attrs) do
      #cree une changeset avec atts et entrie
     changeset =   TimeEntrie.update_changeset(entrie , attrs)
     #IO.inspect changeset
     case changeset.valid? do
      true ->
        Repo.update(changeset)
        {:ok , "modifier avec succes"}

      false ->
        {:error , "une erreur dans les donnes entrees"}
    end

  end








  #PmLogin.SaisieTemps.get_projects_avalable_for_saisie()
  #retourne les taches disponible pour la saisie de temps
  def get_projects_avalable_for_saisie() do
    #sql pour les projects en cours
    sql_query = "SELECT id , title FROM projects WHERE status_id = 3 order by title asc"
    SqlUtilities.fetch_result(sql_query , [])
  end


  #PmLogin.SaisieTemps.get_tasks_by_project
  #retourne la tache disponible par projet
  def get_tasks_by_project(project_id) do
    sql_query =  "SELECT * FROM tasks WHERE project_id = $1 and status_id != 5 and status_id != 6 and status_id != 4 order by title asc"
    params = [project_id]
    SqlUtilities.fetch_result(sql_query , params)

  end


  #retourne les saisie d'une utilisateur pour une date donné
  def get_saisie_by_user_by_date(user_id , date) do

    sql_query = "
    SELECT
    time_entries.*,
    users.username ,
    tasks.title as task_title ,
    projects.title as project_title ,
    v_projects_clients_details.clients_name
    FROM
        time_entries
    JOIN
        users ON users.id = time_entries.user_id
    JOIN
        tasks ON tasks.id = time_entries.task_id
    JOIN
        projects ON projects.id = time_entries.project_id
    JOIN
        v_projects_clients_details on v_projects_clients_details.project_id = time_entries.project_id
    WHERE
         user_id = $1 and date_trunc('day', date_entries) = $2 ::date
    ORDER BY time_entries.inserted_at asc

   "
    params = [user_id ,  date]
    SqlUtilities.fetch_result(sql_query , params)
  end



  #calcule l'heure totale d'une liste de saisie
  def sum_time_values(saisies) do
    IO.inspect saisies
    if Enum.empty?(saisies) do
      Decimal.new(0)
    else
      Enum.reduce(saisies, %Decimal{}, fn saisie, acc ->
        Decimal.add(saisie.time_value, acc)
      end)
    end
  end


  #resumer des saisie par date , group by utilisateur
  def get_resume_saisie_by_date(date) do
    sql_query ="
    select users.id as user_id , users.username , auth.right_id , auth.title , coalesce(sum(time_entries.time_value) , 0 ) time_value , time_entries_validee.inserted_at  from
    users left join
    time_entries on users.id = time_entries.user_id AND date_trunc('day', time_entries.date_entries) = $1 ::date
    left join
    time_entries_validee on users.id = time_entries_validee.user_id and time_entries_validee.date = $1
    join auth on auth.id = users.id
    where
    auth.right_id != 4 and auth.right_id != 100
    group by
    users.id , users.username , auth.title , auth.right_id ,time_entries_validee.inserted_at
    order by sum(time_entries.time_value) asc
    "
    params = [date]
    SqlUtilities.fetch_result(sql_query , params)

  end


  #methode de validation des saisie
  defp can_validate_saisie?(changeset) do
    case changeset.changes.user_validator_id do
      #si user v qui valide est vide
      nil ->
        # L'utilisateur n'a pas été spécifié
        false

      user_validator_id ->
        #verifier si la saisie est n'est pas deja validé , pour eviter les doublons
        validation_line  = get_entrie_validee_line(changeset.changes.date , changeset.changes.user_id)
        if validation_line == nil  do
           #test le droit si admin ou non
          case Login.get_user!(user_validator_id).right_id  do
            1 ->
              true
            _ ->
              false
          end
        else
          false
        end
    end
  end

  #valdidation final de saisie
  #on ajout dans cette fonction si il va y avoir d'autre validation
  defp validation_saisie(saisie_attrs) do
    changeset = TimeEntriesValidee.changeset(%TimeEntriesValidee{} , saisie_attrs)
    IO.puts "makato"
      IO.inspect changeset
     case changeset.valid? do

      true ->

        case can_validate_saisie?(changeset) do
          true ->
            {:ok, changeset}

          false ->
            {:error, "Droit refusé"}
        end

      false ->
        {:error, "Erreur lors de la validation"}
    end



  end


  #method de persistance des saisie validee
   def save_saisie_validee (saisie_attrs) do
      IO.inspect "kakana"
      case validation_saisie(saisie_attrs) do
         {:ok , changeset}
          ->
          Repo.insert(changeset)
          {:ok, "Saisie validée avec succès"}
        {:error , message}
          ->
          {:error , message}

      end

   end






    #creer une condition par rapport au droit
    defp right_id_conditions(right_id) do
      case right_id do
        #tous profil confondue
        0 ->
          "AND ( auth.right_id = 1 OR auth.right_id = 2 OR auth.right_id = 3 ) "
        #only admin
        1 ->
          "AND auth.right_id = 1 "
        2 ->
        #only attributeur
          "AND auth.right_id = 2 "
        3 ->
        #only contributteur
          "AND auth.right_id = 3"
        _ ->
          ""
      end
    end

    #creer une condition par status
    defp status_condition(status) do
      case status do
        #status validee
        1 ->
          "   AND ( time_entries_validee.inserted_at is not null )  "
        #status non validee
        2 ->
          "   AND (time_entries_validee.inserted_at is null ) "
        _ ->
          ""

      end

    end

    defp username_condition(username) do
      case username do
         "" ->
            " "
         _ ->
          " AND  auth.username ilike '%"<>username<>"%' "

      end
    end


    #retourne les saisie par parametre dynamique
    #filtre par date debut date fin  droit et status et username
    def get_resum_saisie_by_params(start_date , end_date , right_id , status , username) do

      sql_query = "
      SELECT
      generated_dates.date_trunc as date,
      auth.id AS user_id,
      COALESCE(SUM(time_entries.time_value), 0) AS time_value,
      auth.username ,
      auth.title ,
      auth.right_id ,
      time_entries_validee.inserted_at as validation_date ,
        case
          when time_entries_validee.inserted_at is null  then false
          else true
        end as status
      FROM
      (SELECT generate_series(
        $1 ::date,
        $2 ::date,
        '1 day'::interval
      )::date AS date_trunc) AS generated_dates
      LEFT JOIN
      auth ON true
      LEFT JOIN
      time_entries ON generated_dates.date_trunc = date_trunc('day', time_entries.date_entries)
                    AND auth.id = time_entries.user_id
      LEFT JOIN time_entries_validee ON auth.id = time_entries_validee.user_id and generated_dates.date_trunc = time_entries_validee.date
      WHERE
      EXTRACT(ISODOW FROM generated_dates.date_trunc) BETWEEN 1 AND 7 -- Exclure samedi et dimanche (1=lundi, 2=mardi, ..., 7=dimanche)
      AND auth.right_id != 4 and auth.right_id != 100 "<> right_id_conditions(right_id) <>"  "<> status_condition(status) <> " "<> username_condition(username) <> "
      GROUP BY
      generated_dates.date_trunc, auth.id, auth.username , time_entries_validee.inserted_at , auth.title , auth.right_id
      ORDER BY
      generated_dates.date_trunc "



      params = [start_date , end_date]
      SqlUtilities.fetch_result(sql_query , params)

    end


    def get_entrie_by_id(id) do
      Repo.get!(TimeEntrie , id)

    end

    def delete_entrie(entrie_id) do
    # Supprimer l'entrée de la base de données
        entrie_to_delete = get_entrie_by_id(entrie_id)
        case Repo.delete(entrie_to_delete) do
          {:ok, _} ->
            # Si la suppression réussit, envoyer une réponse sans modifier le socket
            {:ok, "saisie supprimé"}
          {:error, _} ->
            # Si la suppression échoue, vous pouvez gérer l'erreur, par exemple, afficher un message d'erreur à l'utilisateur
            {:error , "suppression echoué"}
        end
    end


    def get_entries_by_ids(ids) do
      Enum.map(ids, &get_entrie_by_id/1)
    end


    #verification status de l'entree si il n'est pas encore validable
    # def can_validate_an_entrie(entrie) do
    #  if entrie.validation_status == 0 do
    #    true
    #  else
    #   false
    #  end
    #end

    #creer une changeset de validation pour une entrie
   # def get_validation_entrie_changeset(entrie) do
   #   TimeEntrie.validation_changeset(entrie , %{validation_status: 1 })  #%{validation_status: 1 } => status pour marquer une ligne validee
   # end

   # def validate_entries(entries) do
   # entries
   #   |> Enum.filter(&can_validate_an_entrie/1)
   #   |> Enum.map(&get_validation_entrie_changeset/1)
   # end


    #creer une changeset pour une nouvelle ligne de time_entries_validee
   # def create_entrie_validee_line_changeset(date_saisie , user_saisie , user_validator , totale_time_value , status) do
   #   TimeEntriesValidee.create_changeset(%TimeEntriesValidee{} , %{date: date_saisie , time_value: totale_time_value , user_id: user_saisie , user_validator_id: user_validator ,validation_status: status})

   # end


   def test() do
    Repo.all(TimeEntrie)
   end


    def get_entrie_validee_line(date , user_id) do
      user_validator_query = from uv in User , select: uv.username

      query =
        from t_v in TimeEntriesValidee,
          where: t_v.date == ^date and t_v.user_id == ^user_id ,
          preload: [user_validator: ^user_validator_query]
          Repo.one(query)
    end

    def get_validation_line_by_id(validation_line_id) do
      Repo.get!(TimeEntriesValidee , validation_line_id)
    end


    def delete_validation_line(validation_line_id) do
      validation_to_delete = get_validation_line_by_id(validation_line_id)
      case Repo.delete(validation_to_delete) do
          {:ok, _} ->
            # suppresion reussit
            {:ok, "saisie supprimé"}
          {:error, _} ->
            # errreur
            {:error , "suppression echoué"}
        end
    end


    #PmLogin.SaisieTemps.get_client_details_by_rpoject(69)
    #fonction pour avoir les information rattacher a un projet
    #return les details en tant que map
    def get_client_details_by_rpoject(project_id) do
      sql_query =  "SELECT * FROM v_projects_clients_details WHERE project_id = $1"
      params =  [project_id]
      #extract l'entete du list car cette liste return tjr une element
      hd(SqlUtilities.fetch_result(sql_query , params))
    end




  end
