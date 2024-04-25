var authorizedInputs = {
  Admin: [
    "task_title",
    "task_description",
    "parent_task",
    "assigned_person",
    "due_date",
    "start_date",
    "original_estimate",
    "progress",
    "save",
    "curr_user",
    "pro_id",
    "status_id",
    "priority_id",
    "task_deadline",
  ],
  Attributeur: [
    "task_title",
    "task_description",
    "parent_task",
    "assigned_person",
    "due_date",
    "start_date",
    "original_estimate",
    "progress",
    "save",
    "curr_user",
    "pro_id",
    "status_id",
    "priority_id",
    "task_deadline",
  ],
  Contributeur: [
    "task_title",
    "task_description",
    "progress",
    "save",
    "curr_user",
    "pro_id",
    "status_id",
    "priority_id",
    "task_deadline",
  ],
  // Ajoutez d'autres profils et leurs listes d'inputs autorisés si nécessaire
};

function toggleInputs(profile) {
  // Sélectionnez tous les champs de formulaire
  const inputs = document.querySelectorAll("input, textarea, select");
  const profileInputs = authorizedInputs[profile];
  // console.log(profileInputs, profile);
  // Parcourez chaque champ de formulaire
  inputs.forEach(function (input) {
    // Vérifiez si le champ fait partie des inputs autorisés pour le profil

    if (profileInputs && profileInputs.includes(input.name)) {
      // Activer le champ si autorisé pour ce profil
      // console.log(input.id);
      input.removeAttribute("disabled");
    } else {
      // Désactiver le champ s'il n'est pas autorisé pour ce profil
      input.disabled = true;
    }
  });
}

function isFirstDateBeforeSecondDate(date1, date2) {
  // Convertir les dates en objets Date
  var firstDate = new Date(date1);
  var secondDate = new Date(date2);

  // Comparer les dates
  return firstDate < secondDate;
}

export function desactivateAllinputs() {
  // Sélection de la div principale
  var mainDiv = document.getElementById("showing_task");

  // Sélection de tous les éléments de formulaire dans la div principale
  var inputs = mainDiv.querySelectorAll("input, textarea, select");

  // Parcourir tous les éléments de formulaire et activer les champs
  inputs.forEach(function (input) {
    input.disabled = true;
  });
}

export function handleClickOnModifBtn(profile) {
  var saveBtn = document.getElementById("save");
  var cancelBtn = document.getElementById("cancel");
  var modifBtn = document.getElementById("modify");
  // var task_input = document.getElementById("task_title");
  saveBtn.style.display = "inline-block";
  saveBtn.style.cursor = "pointer";
  cancelBtn.style.display = "inline-block";
  cancelBtn.style.cursor = "pointer";
  modifBtn.style.display = "contents";
  modifBtn.style.cursor = "default";
  toggleInputs(profile);
}

export function handleClickOnCancelBtn() {
  var saveBtn = document.getElementById("save");
  var cancelBtn = document.getElementById("cancel");
  var modifBtn = document.getElementById("modify");

  saveBtn.style.display = "contents";
  saveBtn.style.cursor = "default";
  cancelBtn.style.display = "contents";
  cancelBtn.style.cursor = "default";
  modifBtn.style.display = "inline-block";
  modifBtn.style.cursor = "pointer";
  desactivateAllinputs();
}

// Fonction pour valider la saisie dans le champ "progress"
function validateProgressInput(value) {
  // Vérifie si la valeur est un nombre
  if (!isNaN(value)) {
    // Vérifie si la valeur est comprise entre 0 et 100
    if (value >= 0 && value <= 100) {
      // La valeur est valide
      // console.log("La valeur est valide :", value);
      return true;
    } else {
      // La valeur est en dehors de la plage autorisée
      //console.log("La valeur doit être comprise entre 0 et 100");
      return false;
    }
  } else {
    // La valeur n'est pas un nombre
    //console.log("La valeur doit être un nombre");
    return false;
  }
}

function validateDateInputs() {
  // Récupérer les éléments input des champs de date
  var startDateInput = document.getElementById("start_date");
  var dueDateInput = document.getElementById("due_date");

  // Récupérer les valeurs des champs de date
  var startDateValue = startDateInput.value;
  var dueDateValue = dueDateInput.value;

  // Réinitialiser les messages d'erreur dans les labels
  document.getElementById("start_date_error").textContent =
    "La date d'échéance ne peut pas être antérieure à la date de début";
  document.getElementById("start_date_error").style.visibility = "hidden";
  document.getElementById("due_date_error").textContent =
    "La date d'échéance ne peut pas être antérieure à la date de début";
  document.getElementById("due_date_error").style.visibility = "hidden";

  // Vérifier si les champs de date sont vides
  if (!startDateValue) {
    document.getElementById("start_date_error").textContent =
      "Veuillez entrer une date de début";
    document.getElementById("start_date_error").style.visibility = "";
    return false;
  }

  if (!dueDateValue) {
    document.getElementById("due_date_error").textContent =
      "Veuillez entrer une date d'échéance";
    document.getElementById("due_date_error").style.visibility = "";
    return false;
  }

  // Vérifier si les dates sont au bon format
  if (isNaN(Date.parse(startDateValue))) {
    document.getElementById("start_date_error").textContent =
      "Format de date invalide";
    document.getElementById("start_date_error").style.visibility = "";
    return false;
  }

  if (isNaN(Date.parse(dueDateValue))) {
    document.getElementById("due_date_error").textContent =
      "Format de date invalide";
    document.getElementById("due_date_error").style.visibility = "";
    return false;
  }

  // Vérifier si la date d'échéance est antérieure à la date de début
  if (isFirstDateBeforeSecondDate(dueDateValue, startDateValue)) {
    document.getElementById("due_date_error").textContent =
      "La date d'échéance ne peut pas être antérieure à la date de début";
    document.getElementById("due_date_error").style.visibility = "";
    return false;
  }

  return true;
}

function formatDecimalVal(value) {
  var numValue = parseFloat(value);
  var formattedValue = numValue.toFixed(2);
  return formattedValue;
}

function validateEstimationInput(value) {
  var numValue = parseFloat(value);

  // Vérifier si la valeur est un nombre
  if (isNaN(numValue)) {
    // console.log("La valeur entrée n'est pas un nombre valide.");
    return false;
  }

  // Vérifier si la valeur est négative
  if (numValue < 0) {
    //console.log("La valeur ne peut pas être négative.");
    return false;
  }

  return true;
}

function formatNumberInput(value) {
  // Remplacez toutes les caractères non numériques par une chaîne vide
  return value.replace(/\D/g, "");
}

function handleProgressInput(event) {
  formated_value = formatNumberInput(this.value);
  is_valid = validateProgressInput(this.value);
  //console.log(this.value, formated_value, is_valid);
  if (is_valid) {
    this.value = formated_value;
  } else this.value = "";
}

function handleDateInputChange(event) {
  // Récupérer l'élément input qui a déclenché l'événement
  var input = event.target;
  console.log("makato");
  // Valider la valeur saisie dans le champ de date
  console.log(validateDateInputs());

  // Vous pouvez ajouter d'autres actions en fonction de la validation ici
}

function handleEstimationInput(event) {
  let filtredval = this.value.replace(/[^0-9.]/g, "");
  console.log(filtredval);
  val = parseFloat(filtredval);
  console.log(isNaN(val), val, filtredval);
  if (!isNaN(val) || val > 0) {
    console.log(filtredval);
    //this.value = filtredval;
    let decimalLength = (filtredval.split(".")[1] || "").length;
    //console.log(decimalLength);
    if (decimalLength > 2) {
      valeur = parseFloat(filtredval).toFixed(2);
      this.value = valeur; // Limiter à deux chiffres après la virgule
    }
  } else this.value = "";
}

function loadButtonAction(profile) {
  var modifBtn = document.getElementById("modify");
  modifBtn.addEventListener("click", function () {
    handleClickOnModifBtn(profile);
  });

  var cancelBtn = document.getElementById("cancel");
  cancelBtn.addEventListener("click", function () {
    handleClickOnCancelBtn();
  });
}

function loadAllInputsEvent() {
  var progressInput = document.getElementById("progress");
  progressInput.addEventListener("input", handleProgressInput);
  // Sélectionner les éléments input des champs de date
  var startDateInput = document.getElementById("start_date");
  var dueDateInput = document.getElementById("due_date");

  var estimationInput = document.getElementById("estimation_val");
  console.log(estimationInput);
  estimationInput.addEventListener("input", handleEstimationInput);

  // Ajouter un écouteur d'événements pour surveiller les modifications dans le champ de date de début
  startDateInput.addEventListener("change", handleDateInputChange);

  // Ajouter un écouteur d'événements pour surveiller les modifications dans le champ de date d'échéance
  dueDateInput.addEventListener("change", handleDateInputChange);
}

function filterInput(input) {
  // Remplace tout ce qui n'est ni un chiffre ni un point par une chaîne vide
  return input.replace(/\D/g, "");
}

export function showTask(profile) {
  var saveBtn = document.getElementById("save");
  saveBtn.style.display = "contents";
  loadButtonAction(profile);

  loadAllInputsEvent();
}
