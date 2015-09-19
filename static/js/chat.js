
function bindEventSource () {
    var es = new EventSource('/stream');
    var chatMessages = document.getElementById("chat").children[1];
    es.onmessage = function (evt) {
      chatMessages.innerHTML += "<tr><td>" + evt.data + "</td></tr>";
    };
    es.onerror = function (err) {
      console.error("Error occured:", err);
    };
}


window.onload = function () {
  bindEventSource();
};
