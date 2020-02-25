-- Init the payload module and execute its early phase:
payload = LFS.payload()
payload.early()

mqttwrap = require ("mqttwrap")
bme680wrap = require ("bme680wrap")
ccs811wrap = require ("ccs811wrap")
regularntp = require ("regularntp")
ca = require ("ca")
logger = require ("filelog")
flashsettings = require ("flashsettings")

-- time_boot is set and updated by the regularntp module:
time_boot = nil
ota_host = "192.168.1.10"
mqtt_host = "homemqtt.skrewz.net"
mqtt_port = 8883;

myname = flashsettings.get('myname',"c"..node.chipid())
location = flashsettings.get('location','unknown')

wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function(T)
  print("Associated to \""..T.SSID.."\" via BSSID "..T.BSSID)
end)

wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T)
  print("Station IP: "..T.IP.."\nSubnet mask: "..T.netmask.."\nGateway IP: "..T.gateway)

  -- Asynchronously start synchronizing NTP:
  regularntp.on("sync",function()
    print("NTP: synced")
  end)
  regularntp.once_ntp()
  regularntp.start_timer()

  mqttwrap.on("message", function(topic, data)
    print("MQTT: inbound publish on ".. topic .. ":" )
    if data ~= nil then
      print(data)
    end

    -- This admittedly isn't as generic as you might want it to be:
    if "command/settings/"..myname.."/location" == topic then
      flashsettings.set("location",data)
      node.restart()
    end
    if "command/flash/"..myname == topic then
      print ("Got hit on commands/flash/"..myname.." so flashing...")
      LFS.HTTP_OTA(ota_host, '/imgs/', myname..'.img')
    end
  end)


  mqttwrap.on("err",function() logger.writeln("activity", "mqtt hard error"); node.restart() end)
  mqttwrap.on("disconnect",function() logger.writeln("activity", "mqtt disconnect") end)
  mqttwrap.reconnect(mqtt_host, mqtt_port, function()

    local ip = wifi.sta.getip()
    local b_basic,b_extended = node.bootreason()
    mqttwrap.maybepublish("state/"..myname.."/connected", string.format('{"myname":"%s","ip":"%s","bootreason":{"basic":%d,"extended":%d}}',myname,ip,b_basic,b_extended), 0, 0)

    mqttwrap.subscribe("command/flash/"..myname,0)
    mqttwrap.subscribe("command/settings/"..myname.."/#",0)

    mdns.register(myname)
    local ip = wifi.sta.getip()
    print("mdns registered on " .. myname ..".local, and have ip="..ip)

    payload.main()


  end)
end)

wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function(T)
  print("WiFi: lost. Rebooting")
  node.restart()
end)
