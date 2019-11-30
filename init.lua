-- Jakub Trzebiatowski 2019

API_KEY = "IHNKTJICVHTT5RJ8"

wifi.sta.autoconnect(0) -- disable auto connect beacause for some reason it doesn't work - maybe it's something with stationap mode
ds18b20 = require("ds18b20")

function postData(temp)
    local url = "http://api.thingspeak.com/update?api_key" .. API_KEY .. "&field1=" .. temp
    print("GET " .. url)
    http.get(url, nil, function(code, data)
        if (code < 0) then
          print("HTTP request failed, code: " .. code)
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

function readTempAndPostData()
    local pin = 3 -- gpio0 = 3, gpio2 = 4

    local function readout(temp)
        if ds18b20.sens then
            print("Total number of DS18B20 sensors: ".. #ds18b20.sens)
            for i, s in ipairs(ds18b20.sens) do
                print(string.format("  sensor #%d address: %s%s",  i, ('%02X:%02X:%02X:%02X:%02X:%02X:%02X:%02X'):format(s:byte(1,8)), s:byte(9) == 1 and " (parasite)" or ""))
            end
        end
        for addr, temp in pairs(temp) do
            print(string.format("Sensor %s: %s °C", ('%02X:%02X:%02X:%02X:%02X:%02X:%02X:%02X'):format(addr:byte(1,8)), temp))
            postData(temp)
        end
    end

    ds18b20:read_temp(readout, pin, ds18b20.C)
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



-- watchdog below
function tryToConnect()
    name, password, channel = wifi.sta.getconfig()
    print("periodic wifi check, name: " .. name .. ", password: " .. password .. ", channel: " .. channel)
    ip, nm, gw = wifi.sta.getip()
    if ip == nil then
        print("tryingToConnect");
        tryToConnectToPreconfiguredAp()
        wifi.sta.connect()
    else
        print("connected already, ip:" .. ip .. " gw:" .. gw .. " nm:" .. nm);
        readTempAndPostData()
    end
end

local mytimer = tmr.create()

mytimer:register(20000, tmr.ALARM_AUTO, tryToConnect)
mytimer:start()
