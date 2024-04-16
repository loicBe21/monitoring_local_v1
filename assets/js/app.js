// We import the CSS which is extracted to its own file by esbuild.
// Remove this line if you add a your own CSS build pipeline (e.g postcss).
import "../css/app.css";

import "./BoardControle.js";

import 'tom-select'
import { addRow, haveLineNotSaved } from "./tom_select_saisie_page.js";
import TomSelect from "tom-select";



document.addEventListener('DOMContentLoaded', function () {
  // Vérifier si les éléments existent sur la page
  const tableBody = document.getElementById('record-table-body');
  const addRowLink = document.getElementById('addRowIcon');
  const dataContainer = document.getElementById('data-container');

  // Vérifier si les éléments nécessaires existent
  if (tableBody && addRowLink && dataContainer) {
    // Récupérer les données uniquement si les éléments existent
    const userId = dataContainer.dataset.userId;
    //console.log(userId)
    const date = dataContainer.dataset.today;
    //console.log(date)
    const username = dataContainer.dataset.username;
    //console.log(username)
    //console.log(dataContainer.dataset.projects)
    const projects = JSON.parse(dataContainer.dataset.projects);
    //console.log(projects)

    // Ajouter un écouteur d'événements uniquement si l'icône d'ajout de ligne existe
    addRowLink.addEventListener('click', function () {
     
      lineNotSaved = haveLineNotSaved(tableBody);
      console.log(lineNotSaved);
      if (!lineNotSaved) {
        addRow(tableBody, TomSelect, userId, date, username, projects);
      }
      else{
       
        var addRowIcon = document.querySelector('#addRowIcon i');
        console.log(addRowIcon);
        addRowLink.classList.add('non-cliquable');
        addRowIcon.style.cursor = 'not-allowed';
        
      }
      
      
    });
  }

 
 
});



/*
var test =





  new TomSelect('#select-person');




console.log(test);
*/


//import "./table_saisie_temp_controle.js"

// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

require("bootstrap-icons/font/bootstrap-icons.css");
require("material-icons/iconfont/material-icons.css");

// import 'bootstrap-icons/font/bootstrap-icons.css';
// import 'material-icons/iconfont/material-icons.css';

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import { Sortable, Plugins } from "@shopify/draggable";
import topbar from "../vendor/topbar";
import {
  DoughNutChart,
  HorizontalBarChart,
  StackedBarChart,
  LineChart,
  SurveyChart
} from "./chart.js";
import chart from "chart.js/dist/chart";


const Hooks = {};

// Hooks.DoughNutChart = {
//   mounted() {
//     const { labels_tasks_by_contributors, values_tasks_by_contributors } = JSON.parse(this.el.dataset.chartData)
//     this.chart = new DoughNutChart(this.el, labels_tasks_by_contributors, values_tasks_by_contributors)
//   }
// }




/* hooks phoenix pour les changement couleur des lignes survolé
mettre cette hooks en attribut du balise <table></table> si le table a besoin de cette fonctionalité
NB : a mettre uniquement sur une element html table

*/

Hooks.tableHover = {
  mounted() {
    const table = this.el; // Récupérer la table à partir de this.el

    table.querySelectorAll('tbody tr').forEach(row => {
      let currentColor = '';

      row.addEventListener('mouseover', () => {
        currentColor = row.style.backgroundColor;
        row.style.backgroundColor = '#60b0f0';
      });

      row.addEventListener('mouseout', () => {
        row.style.backgroundColor = currentColor;
      });
    });
  }
};

Hooks.CustomSampleSelect = {
  mounted() {
    console.log("CustomSampleSelect hook initialized");

    // Récupérer l'élément select
    var selectElement = document.getElementById("mySelect");

    // Assurez-vous que l'élément select est rendu dans le DOM
    if (selectElement) {
      console.log("Element found:", selectElement);

      // Initialisez TomSelect avec l'élément select s'il n'existe pas déjà d'instance
      if (!selectElement.tomselect) {
        selectElement.tomselect = new TomSelect(selectElement, {
          // Configurations de TomSelect ici
          create: false,
          sortField: {
            field: "text",
            direction: "asc"
          }
        });
        console.log("TomSelect options:", selectElement.tomselect.options);
      }
    } else {
      console.error("Select element not found");
    }
  },
  updated() {
    console.log("CustomSampleSelect hook updated");

    // Récupérer l'élément select
    var selectElement = document.getElementById("mySelect");

    // Vérifiez si une instance de TomSelect est attachée à l'élément select
    if (selectElement && selectElement.tomselect) {
      console.log("Element found:", selectElement);

      // Supprimez toutes les options actuelles de TomSelect
      selectElement.tomselect.clearOptions();

      // Ajoutez de nouvelles options à TomSelect à partir de l'élément select
      var selectOptions = selectElement.querySelectorAll("option");
      selectOptions.forEach(function (option) {
        selectElement.tomselect.addOption({
          value: option.value,
          text: option.textContent
        });
      });

      // Actualisez le TomSelect pour refléter les modifications
      selectElement.tomselect.refreshOptions();
    } else {
      console.error("Select element or TomSelect instance not found");
    }
  }
};






Hooks.CsvExportHook = {
  mounted() {
    this.handleExportClick = this.handleExportClick.bind(this);
    this.el.addEventListener("click", this.handleExportClick);
  },
  destroyed() {
    this.el.removeEventListener("click", this.handleExportClick);
  },

 


  handleExportClick(event) {

  

  

    let csvData = this.el.getAttribute("data-csv");
    console.log("avant :" ,csvData)
    csvData = csvData.replace(/\\r\\n/g, '\n')
    //let test = "Name,Age,City\nJohn,30,New York\nJane,25,San Francisco\nBob,35,Chicago";
    console.log ("apres :" ,csvData)
    // Créer un objet Blob à partir de la chaîne CSV
    const blob = new Blob([csvData], { type: 'text/csv;charset=utf-8;' });

    // Créer un élément <a> pour télécharger le fichier CSV
    const link = document.createElement('a');
    link.href = window.URL.createObjectURL(blob);
    link.download = 'exemple.csv';

    // Ajouter l'élément <a> à la page
    document.body.appendChild(link);

    // Simuler un clic sur le lien pour déclencher le téléchargement
    link.click();

    // Supprimer l'élément <a> après le téléchargement
    document.body.removeChild(link);

    // ... Autres actions à effectuer avec csvData ...
  },


};

Hooks.HorizontalBarChart = {
  mounted() {
    const { labels_tasks_by_contributors, values_tasks_by_contributors } =
      JSON.parse(this.el.dataset.chartData);
    this.chart = new HorizontalBarChart(
      this.el,
      labels_tasks_by_contributors,
      values_tasks_by_contributors
    );
  },
};

Hooks.StackedBarChart = {
  mounted() {
    const {
      values_tasks_todo_by_month,
      values_blocking_tasks_by_month,
      values_tasks_in_progress_by_month,
      values_tasks_in_control_by_month,
      values_tasks_achieved_by_month,
    } = JSON.parse(this.el.dataset.chartData);
    this.chart = new StackedBarChart(
      this.el,
      values_tasks_todo_by_month,
      values_blocking_tasks_by_month,
      values_tasks_in_progress_by_month,
      values_tasks_in_control_by_month,
      values_tasks_achieved_by_month
    );
  },
};


Hooks.SurveyChart = {
  mounted() {
    console.log("is mounted");

    const { values } = JSON.parse(this.el.dataset.chartData);

    this.mychart = new SurveyChart(this.el, values);
  }
};

// Hooks.LineChart = {
//   mounted() {
//     const { values_tasks_todo_by_month, values_blocking_tasks_by_month, values_tasks_in_progress_by_month, values_tasks_in_control_by_month, values_tasks_achieved_by_month } = JSON.parse(this.el.dataset.chartData)
//     this.chart = new LineChart(this.el, values_tasks_todo_by_month, values_blocking_tasks_by_month, values_tasks_in_progress_by_month, values_tasks_in_control_by_month, values_tasks_achieved_by_month)
//   }
// }

Hooks.Board = {
  mounted() {
    this.initDraggables();
  },

  updated() {
    this.sortableCard.destroy();
    this.sortableStage.destroy();
    this.initDraggables();
  },

  initDraggables() {
    this.sortableCard = new Sortable(
      document.querySelectorAll(".stage__cards"),
      {
        draggable: ".card",
        mirror: {
          constrainDimensions: true,
        },
        swapAnimation: {
          duration: 200,
          easingFunction: "ease-in-out",
        },
        plugins: [Plugins.SwapAnimation],
      }
    );

    this.sortableCard.on("sortable:stop", (event) => {
      const source = event.data.dragEvent.data.source;
      const cardId = parseInt(source.getAttribute("data-card-id"));
      const newStageId = parseInt(
        event.data.newContainer.getAttribute("data-stage-id")
      );
      const newIndex = parseInt(event.data.newIndex);
      const cardPayload = {
        card: {
          id: cardId,
          stage_id: newStageId,
          position: newIndex,
        },
      };
      this.pushEvent("update_card", cardPayload);
    });

    this.sortableStage = new Sortable(document.querySelectorAll(".board"), {
      draggable: ".stage",
      handle: ".draggable-handle",
      mirror: {
        constrainDimensions: true,
        yAxis: false,
      },
    });

    this.sortableStage.on("sortable:stop", (event) => {
      const source = event.data.dragEvent.data.source;
      const stageId = parseInt(source.getAttribute("data-stage-id"));
      const newIndex = parseInt(event.data.newIndex);
      const stagePayload = {
        stage: {
          id: stageId,
          position: newIndex,
        },
      };
      this.pushEvent("update_stage", stagePayload);
    });
  },
};

Hooks.AnimateAlert = {
  mounted() {
    // console.log("tafiditra alert")
    this.handleEvent("AnimateAlert", ({}) => this.reset_opacity());
  },
  updated() {},
  reset_opacity() {
    var alert = document.querySelector("#alert_anim");
    alert.style.opacity = 1;
    window.setTimeout(function () {
      /* alert.style.opacity = 0; */
      alert.style.display = "none";
    }, 2000);
  },
  anim_onload() {
    var alerts = document.querySelectorAll(".alert");
    //  console.log(alerts);

    alerts.forEach((item) => {
      item.style.opacity = 1;
      item.onload = window.setTimeout(function () {
        item.style.opacity = 0;
      }, 2000);
    });

    for (var i = 0; i < alerts.length; i++) {
      alerts[i].style.opacity = 1;
      alerts[i].onload = window.setTimeout(function () {
        alerts[i].style.opacity = 0;
      }, 2000);
    }
  },
};

Hooks.blurHook = {
  mounted() {
    // console.log("tafiditra blurHook")
    this.handleEvent("blurBody", ({ param1, param2 }) =>
      // console.log(param1)
      this.blurBody()
    );
  },
  blurBody() {
    var body = document.body;
    var request_form = document.querySelector("#the_request_form");
    // console.log(request_form);

    // console.log(body);
    body.style.opacity = 0.5;

    // var modal = document.querySelector(".modal-container");
    // console.log(modal);
    // modal.style.filter = "blur(1px)";
    request_form.style.opacity = 1;
  },
};

Hooks.MessageBody = {
  mounted() {
    var messageBody = document.querySelector("#messageBody");
    this.handleEvent(
      "updateScroll",
      ({}) =>
        (messageBody.scrollTop =
          messageBody.scrollHeight - messageBody.clientHeight)
    );
  },
};

// Get url location
Hooks.urlProcess = {
  mounted() {
    let main = document.querySelector("#main");

    var url = window.location.href;

    // Ternary function
    url.includes("/logs")
      ? main.classList.remove("container")
      : main.classList.add("container");
  },
};

Hooks.SpinTest = {
  mounted() {
    // console.log("tafiditra hook")
    this.handleEvent("SpinTest", ({}) => this.spin_icon());
    this.handleEvent("SpinComment", ({}) => this.spin_comment_icon());
  },
  spin_icon() {
    var spins = document.querySelectorAll(".notif__load");
    // console.log(spin);
    // spins.classList.add('rotate__icon');
    // console.log(spin);
    // window.setTimeout(function(){spins.classList.remove('rotate__icon');}, 500);
    // console.log('notif')
    spins.forEach((item) => {
      item.classList.add("new__rotate__icon");
    });

    spins.forEach((item) => {
      window.setTimeout(function () {
        item.classList.remove("new__rotate__icon");
      }, 500);
    });
  },
  spin_comment_icon() {
    // console.log('comment')
    var clock_comment = document.getElementById("clock_comment");
    // console.log(clock_comment);
    clock_comment.classList.add("rotate__icon");
    // console.log(clock_comment);
    window.setTimeout(function () {
      clock_comment.classList.remove("rotate__icon");
    }, 500);
    // console.log(clock_comment);
  },
};

let navToggle = document.querySelector(".nav__toggle");
let navWrapper = document.querySelector(".nav__wrapper");
navToggle.addEventListener("click", function () {
  if (navWrapper.classList.contains("active")) {
    this.setAttribute("aria-expanded", "false");
    this.setAttribute("aria-label", "menu");
    navWrapper.classList.remove("active");
  } else {
    navWrapper.classList.add("active");
    this.setAttribute("aria-label", "close menu");
    this.setAttribute("aria-expanded", "true");
  }
});
 // Récupérez l'élément par son ID
 var copyrightIcon = document.getElementById('copyright__icon');

 // Vérifiez si l'élément a été trouvé avant de le modifier
 if (copyrightIcon) {
     copyrightIcon.innerHTML = 'copyright PHIDIA / Project monitoring -2024';
 }
const menuBtn = document.querySelector(".menu-btn");
let menuOpen = false;
menuBtn.addEventListener("click", () => {
  if (!menuOpen) {
    menuBtn.classList.add("open");
    menuOpen = true;
  } else {
    menuBtn.classList.remove("open");
    menuOpen = false;
  }
});

var alerts = document.querySelectorAll(".alert");

alerts.forEach((item) => {
  item.style.opacity = 1;
  item.onload = window.setTimeout(function () {
    item.style.opacity = 0;
  }, 2000);
});

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
});

let topBarScheduled = undefined;

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });

window.addEventListener("phx:page-loading-start", (info) => topbar.show());
window.addEventListener("phx:page-loading-stop", (info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

