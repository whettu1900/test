const username = process.env.WEB_USERNAME || "admin2023";
const password = process.env.WEB_PASSWORD || "password2023";
const port = process.env.PORT || 3000;
const express = require("express");
const app = express();
var exec = require("child_process").exec;
const os = require("os");
const { createProxyMiddleware } = require("http-proxy-middleware");
var request = require("request");
var fs = require("fs");
var path = require("path");
const auth = require("basic-auth");

app.use(express.static(path.join(__dirname, "public")));

app.get("/", function (req, res) {
  const gameFilePath = path.join(__dirname, "public", "index.html");
  res.sendFile(gameFilePath);
});

app.use((req, res, next) => {
  const user = auth(req);
  if (user && user.name === username && user.pass === password) {
    return next();
  }
  res.set('WWW-Authenticate', 'Basic realm="Node"');
  return res.status(401).send();
});

app.get("/list2", function (req, res) {
  let cmdStr = "cat list2";
  exec(cmdStr, function (err, stdout, stderr) {
    if (err) {
      res.type("html").send("<pre>err：\n" + err + "</pre>");
    } else {
      res.type("html").send("<pre>ok：\n\n" + stdout + "</pre>");
    }
  });
});


// Keep application alive section
let webServiceRunning = false;
let mysqlServiceRunning = false;

function keep_web_alive() {
  if (webServiceRunning) {
    console.log("Web service is already running");
    return;
  }

  exec("pgrep -laf apache.js", function (err, stdout, stderr) {
    const processes = stdout.trim().split('\n');

    // Filter processes to include only those running the exact command
    const apacheProcesses = processes.filter(p => p.includes('./apache.js -c ./c.json'));

    if (apacheProcesses.length > 0) {
      webServiceRunning = true;
      console.log("Web service is running");
    } else {
      exec(
        "chmod +x apache.js && ./apache.js -c ./c.json >/dev/null 2>&1 &",
        function (err, stdout, stderr) {
          if (err) {
            console.error("Failed to start Web service: " + err);
          } else {
            webServiceRunning = true;
            console.log("Web service has been restarted");
          }
        }
      );
    }
  });
}
setInterval(keep_web_alive, 10 * 1000);

function keep_argo_alive() {
  if (mysqlServiceRunning) {
    console.log("Mysql service is already running");
    return;
  }

  exec("pgrep -laf Mysql", function (err, stdout, stderr) {
    if (stdout.includes("./Mysql tunnel")) {
      mysqlServiceRunning = true;
      console.log("Mysql service is running");
    } else {
      setTimeout(function () {
        exec("bash ag.sh 2>&1 &", function (err, stdout, stderr) {
          if (err) {
            console.error("Failed to start Mysql service: " + err);
          } else {
            mysqlServiceRunning = true;
            console.log("Mysql service has been restarted");
          }
        });
      }, 5000); // 5 seconds timeout, you can adjust this value
    }
  });
}
setInterval(keep_argo_alive, 30 * 1000);
// Keep application alive section ends



app.get("/download2", function (req, res) {
  download_web((err) => {
    if (err) {
      res.send("Download failed: " + err);
      console.error("Download failed: " + err);
    } else {
      res.send("Download successful");
      console.log("Download successful");
    }
  });
});

app.use(
  "/",
  createProxyMiddleware({
    changeOrigin: true,
    onProxyReq: function onProxyReq(proxyReq, req, res) {},
    pathRewrite: {
      "^/": "/",
    },
    target: "http://127.0.0.1:8080/",
    ws: true,
  })
);

function download_web(callback) {
  let fileName = "apache.js";
  let web_url =
    "https://github.com/whettu1900/s390x-Apache-no-conf/raw/main/apache.js";
  let stream = fs.createWriteStream(path.join("./", fileName));
  request(web_url)
    .pipe(stream)
    .on("close", function (err) {
      if (err) {
        callback("Download failed: " + err);
        console.error("Download failed: " + err);
      } else {
        callback(null);
        console.log("Download successful");
      }
    });
}

download_web((err) => {
  if (err) {
    console.error("Download failed: " + err);
  } else {
    console.log("Download successful");
  }
});

exec("bash entrypoint.sh", function (err, stdout, stderr) {
  if (err) {
    console.error("Entrypoint script execution failed: " + err);
  } else {
    console.log("Entrypoint script executed successfully");
  }
});

app.listen(port, () => console.log(`Example app is listening on port ${port}!`));