import ../../../../../../../src/basolato/view
import ../../layouts/application_view


proc webSocketComponentImpl():Component =
  style "css", style:"""
    <style>
      .form {
        border: 0px;
        box-shadow: none;
      }
    </style>
  """

  tmpli html"""
    <script>
      let socket = new WebSocket("ws://localhost:9000/sample/ws");

      const sendHandler=()=>{
        let outgoingMessage = document.getElementById("input").value;
        socket.send(outgoingMessage);
      }

      const clearHandler=()=>{
        let el = document.getElementById('messages');
        while(el.firstChild){
          el.removeChild(el.firstChild);
        }
      }

      socket.onmessage = function(event) {
        let message = event.data;

        let messageElem = document.createElement('div');
        messageElem.textContent = message;
        document.getElementById('messages').prepend(messageElem);
      }
    </script>
    <form class="$(style.element("form"))">
      <input type="text" id="input">
      <button type="button" onclick="sendHandler()">Send</button>
      <button type="button" onclick="clearHandler()">Delete</button>
    </form>
    <div id="messages"></div>
    $(style)
  """

proc webSocketComponent*():string =
  return $applicationView("Web Socket", webSocketComponentImpl())


proc impl():Component =
  style "css", style:"""
    <style>
      .iframe {
        height: 80vh;
      }
    </style>
  """

  tmpli html"""
    $(style)
    <section>
      <aside>
        <iframe src="/sample/web-socket-component" class="$(style.element("iframe"))"></iframe>
      </aside>
      <aside>
        <iframe src="/sample/web-socket-component" class="$(style.element("iframe"))"></iframe>
      </aside>
    </section>
  """

proc webSocketView*():string =
  return $applicationView("Web Socket", impl())
