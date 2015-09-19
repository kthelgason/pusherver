
function bindEventSource () {
    var es = new EventSource('/stream');
    var chat = document.getElementById("chat");
    es.onmessage = function (evt) {
        console.log(evt.data);
    };

    es.onopen = function () {
      console.log("Opened new connection to server");
    };

    es.onerror = function (err) {
      console.error("Error occured:", err);
    };
}


window.onload = function () {
  bindEventSource();
};
