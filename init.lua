-- Jakub Trzebiatowski 2019

wifi.sta.autoconnect(0) -- disable auto connect beacause for some reason it doesn't work - maybe it's something with stationap mode

function postData()
    http.post("http://api.thingspeak.com/update?api_key=8MVCZUBH994ATU6Q&field1=100", nil, function(code, data)
        if (code < 0) then
          print("HTTP request failed")
        else
          print(code, data)
        end
      end)    
end

function configureAp()
    enduser_setup.manual(true)
    enduser_setup.start(
            function()
                print("Connected to WiFi as:" .. wifi.sta.getip());
                configuredName, configuredPassword = wifi.sta.getconfig();
                if name == configuredName and password == configuredPassword then
                    print("Not storing configuration into flash - configuration already stored");
                else
                    if wifi.sta.config(wifi.sta.getconfig(true)) then
                        -- store config in flash
                        print("Succesfully configured sta (to flash)");
                    else
                        print("Error configuring sta");
                    end
                end

            end,
            function(err, str)
                print("enduser_setup: Err #" .. err .. ": " .. str);
            end
    )
end

function tryToConnectToPreconfiguredAp()
    if not file.exists("eus_params.lua") then
        print("Config file doesn't exist")
        return
    end
    print("Loading config from file")
    p = dofile('eus_params.lua')
    
    station_cfg={}
    station_cfg.ssid=p.wifi_ssid
    station_cfg.pwd=p.wifi_password
    station_cfg.save=false
    print("ssid: \"" .. station_cfg.ssid .. "\", password: \"" .. station_cfg.pwd .. "\"")
    wifi.sta.config(station_cfg)

end

tryToConnectToPreconfiguredAp()
name, password, channel = wifi.sta.getconfig()
print("Starting, name: " .. name .. ", password: " .. password .. ", channel: " .. channel)
if channel == nil or channel == 0 then
    channel = 6
end
print("Starting ap on channel: " .. channel)

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
        postData();
    end
end

local mytimer = tmr.create()

mytimer:register(10000, tmr.ALARM_AUTO, tryToConnect)
mytimer:start()
