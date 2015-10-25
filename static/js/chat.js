
function bindEventSource () {
  var es = new EventSource('/stream');
  var chatMessages = document.getElementById("chat").children[1];
  es.onmessage = function (evt) {
    console.log("new message");
    chatMessages.innerHTML += "<tr><td>" + evt.data + "</td></tr>";
  };
  es.onerror = function (err) {
    console.error("Error occured:", err);
  };
}

function postMessage (message) {
  var req = new XMLHttpRequest();
  req.open("POST", "/message");
  req.onload = function () {
    console.log("posted.");
  };
  req.send(message);
}

function bindSendEvents () {
  var form = document.getElementById("post");
  var messageInput = form.children[0].children[0];
  form.addEventListener("submit", function (e) {
    postMessage(messageInput.value);
    messageInput.value = "";
    e.preventDefault();
  });
}


window.onload = function () {
  bindEventSource();
  bindSendEvents();
};
