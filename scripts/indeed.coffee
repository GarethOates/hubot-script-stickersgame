# Indeed!
#
# indeed - Indeed!
#
# Authors:
#   Jonas Arneberg for Gavin King
#   Daniel André Eikeland for himself

indeeds = [
  "https://i.imgur.com/wAFl0jA.jpg",
  "https://i.imgur.com/LCkD9Fd.jpg",
  "https://i.imgur.com/C7pj4b2.jpg",
  "https://i.imgur.com/fDrY7Kg.jpg",
  "https://i.imgur.com/UnFIVYr.jpg",
  "https://i.imgur.com/eCWW8rp.png",
  "https://i.imgur.com/ZlqNYvm.jpg",
  "https://i.imgur.com/PaKEjqp.jpg",
  "https://i.imgur.com/oTzxITJ.gif",
  "https://i.imgur.com/xQ2wkmV.png",
  "https://i.imgur.com/GIrZAXr.jpg",
  "https://i.imgur.com/HXx4jSX.jpg",
  "https://i.imgur.com/Q59UE20.jpg"
]

module.exports = (robot) ->
  robot.hear /indeed/i, (msg) ->
    msg.send msg.random indeeds