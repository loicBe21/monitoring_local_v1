/*
fichier JS pour la genereration et sauvgarde de ligne de saisie
required TomSelect
a voir aussi TaskController.task_by_project  //api de recuperation des taches et info client par projet
SaisieController.create  //api de sauvgarde d'une ligne
author  : loicRavelo05@gmail.com
*/






import TomSelect from "tom-select";




// Fonction pour sauvegarder une ligne
function saveRow(icon) {
    const row = icon.closest('tr');
    const inputs = row.querySelectorAll('input, select'); // get all inputs 
    const rowData = {}; //les valeur de chaque input
    inputs.forEach(input => {
        rowData[input.name] = input.value;
    });
    // Vous pouvez maintenant soumettre cette ligne de données à votre backend ou effectuer d'autres actions
    console.log("Données à sauvegarder:", rowData);

    // Récupérer le jeton CSRF depuis un champ caché dans le formulaire
    const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

    // Envoi des données au backend avec le jeton CSRF
    fetch('/save_saisie', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': csrfToken  // Inclure le jeton CSRF dans les en-têtes de la requête
        },
        body: JSON.stringify(rowData)
    })
        .then(response => {
            console.log(" response : ", response)
            if (!response.ok) {
                throw new Error('Erreur lors de la sauvegarde des données');
            }
            return response.json();
        })
        .then(data => {
            // Traitement de la réponse du backend
            console.log('Succès:', data.message);
            window.location.reload(); // ou toute autre action que vous voulez effectuer en cas de succès
        })
        .catch(error => {
            console.error('Erreur :', error);
            alert('Une erreur est survenue lors de la sauvegarde. Veuillez vérifier que tous les champs sont bien remplis et au bon format');
        });
}
// Fonction pour supprimer une ligne
function removeRow(icon) {
    icon.closest('tr').remove();
}

// fonction de validation du champ decimal de l'input
function isDecimalValid(inputValue) {
    // Vérifie si la valeur saisie est un nombre décimal valide entre 0 et 20
    const numericValue = parseFloat(inputValue);
    return !isNaN(numericValue) && numericValue >= 0 && numericValue <= 20 ;
}


function isLabelValid(inputValue) {
    // Vérifie si la valeur saisie n'est pas vide et ne dépasse pas 255 caractères
    return inputValue.trim() !== '' && inputValue.length <= 255;
}

function isProjectIdValid(value) {
    // Vérifie si la valeur du champ de sélection de projet n'est pas vide
    return value.trim() !== '';
}

function isTaskValid(selectedTask) {
    // Vérifie si une tâche est sélectionnée
    return selectedTask !== '';
}




// ecouteur d'evenement du champ decimal

function handleDecimalInput(event) {
   // const stringFormat = this.value;

    // Supprimer les signes '+' et '-' de la valeur saisie
    if (this.value.includes('+') || this.value.includes('-')) {
        const formattedValue = stringFormat.replace(/[+-]/g, '');
        this.value = formattedValue;
    }
   
    // Valider la valeur saisie et changer la couleur de la bordure en conséquence
    if (!isDecimalValid(this.value)) {
        this.style.borderColor = 'red'; // Changement de la couleur de la bordure en rouge en cas d'erreur
    } else {
        // Vérifier la longueur de la partie décimale
        const decimalLength = (this.value.split('.')[1] || '').length;
        console.log(decimalLength);
        if (decimalLength > 2) {
            valeur = parseFloat(this.value).toFixed(2);
            this.value = valeur; // Limiter à deux chiffres après la virgule
        }
        this.style.borderColor = 'green'; // Réinitialisation de la couleur de la bordure à sa valeur par défaut
    }
}



function handleLabelInput(event) {
    if (!isLabelValid(this.value)) {
        this.style.borderColor = 'red'; // Changement de la couleur de la bordure en rouge en cas d'erreur
    } else {
        this.style.borderColor = 'green'; // Réinitialisation de la couleur de la bordure à sa valeur par défaut
    }
}



//gestion d'evenement du la liste deroulante des projet
function handleProjectSelectChange(event , task_tom_select) {
    const projectElement = document.querySelector('.project_id');
    const tsControlElement = projectElement.querySelector('.ts-control');
    const selectedProjectId = event.target.value;

    if (!isProjectIdValid(selectedProjectId)) {
        console.log("makato amin red");
        tsControlElement.style.borderColor = 'red'; // Changement de la couleur de la bordure en rouge en cas d'erreur
    } else {
        console.log("makato amin green");
        tsControlElement.style.borderColor = 'green'; // Réinitialisation de la couleur de la bordure à sa valeur par défaut
    }

    // Mise à jour de la liste déroulante des tâches en fonction du projet sélectionné
    updateTaskOptions(selectedProjectId, task_tom_select);
}




/*
ecouteur d'evenement sur la liste deroulante de projet
*/
function handleTaskSelectChange(event) {
    const taskElement = document.querySelector('.task');
    const tsControlElement = taskElement.querySelector('.ts-control');
    const selectedTask = event.target.value;

    if (!isTaskValid(selectedTask)) {
        console.log("La tâche sélectionnée est invalide");
        tsControlElement.style.borderColor = 'red'; // Changement de la couleur de la bordure en rouge en cas d'erreur
    } else {
        console.log("La tâche sélectionnée est valide");
        tsControlElement.style.borderColor = 'green'; // Réinitialisation de la couleur de la bordure à sa valeur par défaut
    }
}





/* fonction qui ajout les couleur par defaut rouge sur les champ puisque les champ sont tous vide lors de la generation d'une nouvelle ligne 
NB : appeler cette  fonction juste apres avoir creer les instance de tomSelect sur les liste deroulante => il y a des div generer juste apres avoir mis une instance de tomSelect sur une liste deroulante (.ts-control)
*/

function applyFieldValidations(tableBody) {

    const taskElement = tableBody.querySelector('.task');
    const tsControlElement1 = taskElement.querySelector('.ts-control');
    tsControlElement1.style.borderColor = 'red';

    const projectElement = tableBody.querySelector('.project_id');
    const tsControlElement = projectElement.querySelector('.ts-control');
    tsControlElement.style.borderColor = 'red';

    const labelInput = tableBody.querySelector('tr:last-child input[name="labels"]');
    // ajout de la couleur intial 
    labelInput.style.borderColor = 'red';
   
}

function lineValidation(tableBody) {
    const labelInput = tableBody.querySelector('tr:last-child input[name="labels"]');
    const taskSelect = tableBody.querySelector('tr:last-child select[name="task"]');
    const projectSelect = tableBody.querySelector('tr:last-child select[name="project_id"]');
    const decimalInput = tableBody.querySelector('tr:last-child input[name="hours"]');

    // Validation du champ de libellé
    const isLabelValidResult = isLabelValid(labelInput.value);

    // Validation du champ de sélection de tâche
    const isTaskValidResult = isTaskValid(taskSelect.value);

    // Validation du champ de sélection de projet
    const isProjectIdValidResult = isProjectIdValid(projectSelect.value);

    // Validation du champ décimal
    const isDecimalValidResult = isDecimalValid(decimalInput.value);

    // Si toutes les validations sont valides, retournez true, sinon retournez false
    return isLabelValidResult && isTaskValidResult && isProjectIdValidResult && isDecimalValidResult;
}

export function haveLineNotSaved(tableBody) {
    const newTaskSelect = tableBody.querySelector('tr:last-child select[name="task"]');
    if (newTaskSelect != null)
        return true;
    else
        return false;
        
}




//fonction de génération dynamique des ligne de saisie
export function addRow(tableBody, TomSelect, userId, date, username, projects) {
    //les element de lignes 
    const newRow = `
        <tr>
            <input type="hidden" name="user_id" value="${userId}">
            <td class="date"><input type="date" name="date" value="${date}"></td>
            <td class="user"><input type="text" name="user" value="${username}" readonly></td>
            <td class="project_id">
                <select name="project_id" id="tom_select">
                    <option value="">Sélectionner un projet</option>
                    ${projects.map(project => `<option value="${project.id}">${project.title}</option>`).join('')}
                </select>
            </td>
            <td class="client">
                <input type="text" name="client_name" value="" readonly>
            </td>
            <td class="task">
                <select name="task" id="tasks_select" placeholder="Sélectioner une tâche"></select>
            </td>
            <td class="labels"><input type="text" name="labels" placeholder="Libellé"></td>
            <td class="temps">
                <input type="number" id="decimal_input" name="hours" step="0.1" value="0.0">
            </td>
            <td class="actions">
                <i title="Sauvegarder" class="bi bi-save" style="cursor: pointer;"></i>
                <i title="Supprimer" id="suppr" class="bi bi-trash" style="cursor: pointer;" ></i>
            </td>
        </tr>
    `;
 
    tableBody.insertAdjacentHTML('beforeend', newRow);
  


    //ajout tomSelect a la liste deroulante des projet
    const newProjectSelect = tableBody.querySelector('tr:last-child select[name="project_id"]');

    new TomSelect(newProjectSelect, {
        // Configuration de TomSelect
        searchable: true,
        sortField: {
            field: "text",
            direction: "asc"
        }
    });

    //creation d'un instance de tomSelect avec la liste deroulante des taches dans la ligne nouvellement genrer
    const newTaskSelect = tableBody.querySelector('tr:last-child select[name="task"]');
    newTaskSelect.addEventListener('change', handleTaskSelectChange);
    //console.log(newTaskSelect)
    task_tom_select = new TomSelect(newTaskSelect, {
        // Configuration de TomSelect
        searchable: true,
        sortField: {
            field: "text",
            direction: "asc"
        }
    });


    //appele de la fonction qui ajoute les style de couleur pardefaut des champ juste apres avoir creer les instance de tomSelect
    applyFieldValidations(tableBody)

    //extract le projet selectioner pour recuperer les tache correspondant
    const projectSelect = document.querySelector('select[name="project_id"]');
    // Ajout d'un écouteur d'événements à projectSelect avec une fonction de rappel
    projectSelect.addEventListener('change', function (event) {
        // Appel de handleProjectSelectChange avec l'objet event et task_tom_select
        handleProjectSelectChange(event, task_tom_select);
    });


    // Ajout d'un écouteur d'événements sur l'entrée décimale pour la validation en direct
    const decimalInput = tableBody.querySelector('tr:last-child input[name="hours"]');
    decimalInput.addEventListener('input', handleDecimalInput);

    
    const labelInput = tableBody.querySelector('tr:last-child input[name="labels"]');
    // Ajout d'un écouteur d'événements sur le champ de texte pour la validation en direct
    labelInput.addEventListener('input', handleLabelInput);

    // Ajoutez les écouteurs d'événements aux icônes sauvegarder et supprimer de la nouvelle ligne
    const newSaveIcon = tableBody.querySelector('.bi-save');
    newSaveIcon.addEventListener('click', function () {
        // Vérifiez la validité des champs de la dernière ligne
        const isValid = lineValidation(tableBody);

        // Si tous les champs sont valides, appelez la fonction saveRow
        if (isValid) {
            saveRow(newSaveIcon);
        } else {
            // Sinon, affichez un message d'erreur ou effectuez une autre action
            console.log('Les champs ne sont pas valides. Veuillez vérifier vos saisies.');
        }
    });

    // suppression des lignes genrer
    const newRemoveIcon = tableBody.querySelector('#suppr');
    console.log(newRemoveIcon)
    newRemoveIcon.addEventListener('click', function () {
        removeRow(newRemoveIcon);
        resetAddRowIcon();
    });




    
   



}
//fonction de mise à jour de la liste déroulante des tâches par projet sélectionné
//appel à une API dans TaskController.task_by_project => retourne les tâches et les détails du client rattaché au projet sélectionné
function updateTaskOptions(selectedProjectId, taskTomSelect) {
    // Votre logique pour mettre à jour les options du menu déroulant des tâches ici
    //console.log('Projet sélectionné:', selectedProjectId);

    // Effectuer une requête AJAX vers votre endpoint backend pour récupérer les tâches associées au projet sélectionné
    fetch(`/tasks/${selectedProjectId}`)
        .then(response => {
            console.log(response)
            if (!response.ok) {
                throw new Error('Erreur lors de la récupération des tâches');
            }
            return response.json();
        })
        .then(data => {
            // Mettre à jour la liste déroulante des tâches avec les données récupérées
            console.log(data)
            const tasks = data.tasks;
            taskTomSelect.clear();
            taskTomSelect.clearOptions(); // Effacer les options précédentes
            tasks.forEach(task => {
                taskTomSelect.addOption({ value: task.id, text: task.title });  //ajout des nouvelles option a l'instance du tomSelect passer en parametres
            });
            // Traitement des détails clients
            const clientDetails = data.client_details;
            // Exemple d'utilisation des détails du client
            // console.log('Nom du client:', clientDetails.clients_name);
            const clientNameInput = document.querySelector('input[name="client_name"]');
            clientNameInput.value = clientDetails.clients_name;
        })
        .catch(error => {
            const clientNameInput = document.querySelector('input[name="client_name"]');
            clientNameInput.value = '';
            taskTomSelect.clear();
            taskTomSelect.clearOptions(); // Effacer les options précédentes
            console.log(taskTomSelect);
            console.error('Erreur :', error);
        });
}


//reset add row icon 
function resetAddRowIcon() {
    var addRowLink = document.getElementById('addRowIcon'); 
    var addRowIcon = document.querySelector('#addRowIcon i');
    addRowLink.classList.remove('non-cliquable');
    addRowIcon.style.cursor = 'pointer';
}


