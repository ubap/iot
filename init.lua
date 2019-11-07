--[[


function startSta()
  print("startedSta");
  t:unregister()


  wifi.setmode(wifi.STATION, false) -- don't store it in flash

end

mytimer:register(60000, tmr.ALARM_SINGLE, startSta)
mytimer:start()
]]--


function configureAp()
    enduser_setup.manual(true)
    enduser_setup.start(
            function()
                print("Connected to WiFi as:" .. wifi.sta.getip());
                if wifi.sta.config(wifi.sta.getconfig(true)) then
                    -- store config in flash
                    print("Succesfully configured sta (to flash)");
                else
                    print("Error configuring sta");
                end

            end,
            function(err, str)
                print("enduser_setup: Err #" .. err .. ": " .. str);
            end
    )
end

wifi.sta.autoconnect(0) -- disable auto connect beacause for some reason it doesn't work - maybe it's something with stationap mode


name, password, channel = wifi.sta.getconfig()
print("starting, name: " .. name .. ", password: " .. password .. ", channel: " .. channel)
if channel == nil or channel == 0 then
    channel = 6
end
print("channel: " .. channel)

wifi.setmode(wifi.STATIONAP, false) -- don't store it in flash

if wifi.ap.config({ ssid = "MyPersonalSSID", pwd = "haslo123456", auth = wifi.WPA2_PSK, save = false, channel = channel }) then
    print("Succesfully configured ap");
else
    print("Error configuring ap");
end

configureAp()

function tryToConnect()
    name, password, channel = wifi.sta.getconfig()
    print("periodic wifi check, name: " .. name .. ", password: " .. password .. ", channel: " .. channel)
    ip, nm, gw = wifi.sta.getip()
    if ip == nil then
        print("tryingToConnect");
        wifi.sta.connect()
    else
        print("connected already, ip:" .. ip .. " gw:" .. gw .. " nm:" .. nm);
    end
end

local mytimer = tmr.create()

mytimer:register(10000, tmr.ALARM_AUTO, tryToConnect)
mytimer:start()
