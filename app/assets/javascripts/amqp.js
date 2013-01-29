//= require mq
//= require swfobject

swfobject.embedSWF(
  "/assets/amqp.swf",
  "AMQPProxy",
  "1",
  "1",
  "9",
  "/assets/expressInstall.swf",
  {},
  {
      allowScriptAccess: "always",
      wmode   : "opaque",
      bgcolor : "#ff0000"
  },
  {}
);