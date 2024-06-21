import {Socket} from "phoenix"
import 'jquery'
import 'chart.js'
import 'trumbowyg'

$(function() {
    var channel
    var meta_token = $("meta[name='channel_token']")
    var summary = {}

    if (meta_token) {
        var token = $(meta_token).attr("content")
        let admin_socket = new Socket("/socket", {params: {token: token}})
        admin_socket.connect()

        // Now that you are connected, you can join channels with a topic:
        channel = admin_socket.channel("books:admin:cart", {})
        channel.join()
          .receive("ok", resp => { console.log("Joined successfully", resp) })
          .receive("error", resp => { console.log("Unable to join", resp) })

        channel.push('reload', {'uri': '/admin'})
          .receive("ok", resp => {
            console.log("resp", resp)
            update_orders(resp["orders"])
            update_summary(resp["summary"])
          })
          .receive("error", resp => { console.log(resp) })

        channel.on('update', order => {
          $("#no-orders").hide()
          update_order(order)
        })

        channel.on('inc-summary', event_data => {
          $("#no-orders-summary").hide()
          var country = event_data["country"]
          var data = summary[country]
          data["count"] ++
          update_country(data)
        })

        channel.on('dec-summary', event_data => {
          $("#no-orders-summary").hide()
          var country = event_data["country"]
          var data = summary[country]
          data["count"] --
          update_country(data)
        })

        channel.on('remove', order => {
          $("#" + order["id"]).remove()
          if ($(".order-row").length == 0) {
            $("#no-orders").show()
          }
        })
    } else {
        console.error("not found meta[name='channel_token']")
    }
  
    function update_country(data) {
      if ($("#summary-" + data["country"]).length > 0) {
        $("#summary-" + data["country"] + "-count").html(data["count"])
      } else {
        var table = $("#orders-summary").html()
        var row = "<tr class='summary-row' id='summary-" + data["country"] + "'>"
        row += "<td id='summary-" + data["country"] + "-country'><span title='" + data["country"] + "'>" + data["flag"] + "</span></td>"
        row += "<td id='summary-" + data["country"] + "-count'>" + data["count"] + "</td>"
        row += "</tr>"
        $("#orders-summary").html(table + row)
      }
      summary[data["country"]] = data
    }

    function ip_country(order) {
      return order["remote_ip"] + " <span title='" + order["country"] + "'>" + order["flag"] + "</span>"
    }

    function order_id(order) {
      return "<a href='" + order["url"] + "' id='" + order["id"] + "'>" + ip_country(order) + "</a>"
    }

    function update_order(order) {
      if ($("#" + order["id"]).length > 0) {
        $("#" + order["id"] + "-state").html(order["state"])
        $("#" + order["id"] + "-ip").html(ip_country(order))
        $("#" + order["id"] + "-price").html(order["total_price"])
        $("#" + order["id"] + "-shipping").html(order["shipping"] ? "yes" : "no")
      } else {
        var table = $("#orders-content").html()
        var row = "<tr class='order-row' id='" + order["id"] + "'><td>" + order_id(order) + "</td>"
        row += "<td id='" + order["id"] + "-state'>" + order["state"] + "</td>"
        row += "<td id='" + order["id"] + "-price'>" + order["total_price"] + "</td>"
        row += "<td id='" + order["id"] + "-shipping'>" + (order["shipping"] ? "yes" : "no") + "</td>"
        row += "</tr>"
        $("#orders-content").html(table + row)
      }
    }

    function update_summary(summary) {
      if (summary.length > 0) {
        $("#no-orders-summary").hide()
        summary.forEach(data => {
          update_country(data)
        })
      } else {
        $(".summary-row").remove()
        $("#no-orders-summary").show()
      }
    }

    function update_orders(orders) {
      if (orders.length > 0) {
        $("#no-orders").hide()
        orders.forEach(order => {
          update_order(order)
        })
      } else {
        $(".order-row").remove()
        $("#no-orders").show()
      }
    }

    $(".trumbowyg").trumbowyg({
      svgPath: '/images/icons.svg'
    })
})
