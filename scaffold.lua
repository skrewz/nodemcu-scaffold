-- Init the payload module and execute its early phase:
payload = LFS.payload()
payload.early()


buildinfo = require ("buildinfo")
flashsettings = require ("flashsettings")
logger = require ("filelog")
mqttwrap = require ("mqttwrap")
regularntp = require ("regularntp")

-- time_boot is set and updated by the regularntp module:
time_boot = nil
ota_host = "192.168.1.10"
mqtt_host = "homemqtt.skrewz.net"
mqtt_port = 8883;

myname = "c"..node.chipid()
location = flashsettings.get('location','unknown')

wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function(T)
  print("Associated to \""..T.SSID.."\" via BSSID "..T.BSSID)
end)

generate_status_json = function ()
    local ip = wifi.sta.getip()
    local b_basic,b_extended = node.bootreason()
    local flash_error_msg = "(undefined)"
    if file.exists("lfs.errormsg") then
      flash_error_msg = file.getcontents("lfs.errormsg")
    end
    local last_modified = "(undefined)"
    if file.exists("lfs.modified") then
      last_modified = file.getcontents("lfs.modified")
    end
    return string.format('{"myname":"%s","ip":"%s","bootreason":{"basic":%d,"extended":%d},"time_boot":%d,"lfs":{"error_msg": "%s","last_modified": "%s"},"build_timestamp": "%s"}',myname,ip,b_basic,b_extended,time_boot,flash_error_msg,last_modified,buildinfo.build_timestamp)
end


wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T)
  print("Station IP: "..T.IP.."\nSubnet mask: "..T.netmask.."\nGateway IP: "..T.gateway)

  -- Synchronously synchronizing NTP (to have clock available for subsequent
  -- calls):
  regularntp.on("sync",function()
    print("NTP: synced")
    regularntp.start_timer()
    mqttwrap.handletopic("command/ping/"..myname, function(topic, data)
      local js = generate_status_json()
      mqttwrap.maybepublish("command/pong/"..myname,js , 0, 0)
    end)
    mqttwrap.handletopic("command/settings/"..myname.."/location", function(topic, data)
      flashsettings.set("location",data)
      node.restart()
    end)
    mqttwrap.handletopic("command/flash/"..myname, function(topic, data)
      print ("Got hit on commands/flash/"..myname.." so flashing...")
      mqttwrap.maybepublish("command/acknowledged/"..myname,"flash command acknowledged", 0, 0)
      LFS.http_ota('192.168.1.10', '/imgs/', myname..'.img')
    end)


    mqttwrap.on("err",function() logger.writeln("activity", "mqtt hard error"); node.restart() end)
    mqttwrap.on("disconnect",function() logger.writeln("activity", "mqtt disconnect") end)
    mqttwrap.reconnect(mqtt_host, mqtt_port, function()

      local js = generate_status_json()
      mqttwrap.maybepublish("state/"..myname.."/connected", js, 0, 0)

      mqttwrap.subscribe("command/flash/"..myname,0)
      mqttwrap.subscribe("command/ping/"..myname,0)
      mqttwrap.subscribe("command/settings/"..myname.."/#",0)

      mdns.register(myname)
      local ip = wifi.sta.getip()
      print("mdns registered on " .. myname ..".local, and have ip="..ip)
      tmr_main = tmr.create()
      tmr_main:register(5000, tmr.ALARM_SINGLE, function ()
        mqttwrap.maybepublish("state/"..myname.."/booted", '{"msg": "Starting main"}', 0, 0)
        payload.main()
      end)
      mqttwrap.maybepublish("state/"..myname.."/booted", '{"msg": "Now booted, delaying for main"}', 0, 0)
      tmr_main:start()


    end)
  end)

  regularntp.once_ntp()


  wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function(T)
    print("WiFi: lost. Rebooting")
    node.restart()
  end)
end)
