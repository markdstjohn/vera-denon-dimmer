local MIN_VOLUME = -80
local MAX_VOLUME = 5

function update_status (lul_device)
  luup.log ("Running update_status")
  luup.inet.wget("http://" .. luup.devices[lul_device].ip .. "/MainZone/index.put.asp?cmd0=aspMainZone_WebUpdateStatus%2F", 5)
  local a,b = luup.inet.wget("http://" .. luup.devices[lul_device].ip .. "/goform/formMainZone_MainZoneXmlStatusLite.xml", 5)
  if a == 0 and b then
     if string.match(b, '<Power><value>([A-Z]+)') == "ON" then
      local dbVolume = tonumber(string.match(b, '<MasterVolume><value>(.%d+)'))
      local loadLevel = math.ceil((dbVolume-MIN_VOLUME)/(MAX_VOLUME-MIN_VOLUME)*100)
      luup.variable_set ("urn:upnp-org:serviceId:SwitchPower1", "Status", "1", lul_device)
      luup.variable_set ("urn:upnp-org:serviceId:Dimming1", "LoadLevelStatus", loadLevel, lul_device)
    else
      luup.variable_set ("urn:upnp-org:serviceId:SwitchPower1", "Status", "0", lul_device)
      luup.variable_set ("urn:upnp-org:serviceId:Dimming1", "LoadLevelStatus", MIN_VOLUME, lul_device)
    end
    luup.variable_set("urn:micasaverde-com:serviceId:HaDevice1", "LastUpdate", os.time())
  end
end

function set_target (lul_device, lul_settings)
  if (lul_settings.newTargetValue == "1") then
    luup.inet.wget("http://" .. luup.devices[lul_device].ip .. "/MainZone/index.put.asp?cmd0=PutZone_OnOff%2FON", 5)
    luup.variable_set ("urn:upnp-org:serviceId:Dimming1", "LoadLevelTarget", 1, lul_device)
    luup.variable_set ("urn:upnp-org:serviceId:Dimming1", "LoadLevelStatus", 1, lul_device)
  else
    luup.inet.wget("http://" .. luup.devices[lul_device].ip .. "/MainZone/index.put.asp?cmd0=PutSystem_OnStandby%2FSTANDBY", 5)
    luup.variable_set ("urn:upnp-org:serviceId:Dimming1", "LoadLevelTarget", 0, lul_device)
    luup.variable_set ("urn:upnp-org:serviceId:Dimming1", "LoadLevelStatus", 0, lul_device)
  end
  luup.variable_set ("urn:upnp-org:serviceId:SwitchPower1", "Target", lul_settings.newTargetValue, lul_device)
  luup.variable_set ("urn:upnp-org:serviceId:SwitchPower1", "Status", lul_settings.newTargetValue, lul_device)
end

function set_load_level_target (lul_device, lul_settings)
  luup.variable_set ("urn:upnp-org:serviceId:Dimming1", "LoadLevelTarget", lul_settings.newLoadlevelTarget, lul_device)
  luup.variable_set ("urn:upnp-org:serviceId:Dimming1", "LoadLevelStatus", lul_settings.newLoadlevelTarget, lul_device)
  local switchOnOff = luup.variable_get ("urn:upnp-org:serviceId:SwitchPower1", "Status", lul_device)
  if (tonumber (lul_settings.newLoadlevelTarget, 10) == 0) then
    if (switchOnOff == "1") then
      luup.inet.wget("http://" .. luup.devices[lul_device].ip .. "/MainZone/index.put.asp?cmd0=PutSystem_OnStandby%2FSTANDBY", 5)
    end
    luup.variable_set ("urn:upnp-org:serviceId:SwitchPower1", "Status", "0", lul_device)
  else
    if (switchOnOff == "0") then
      luup.inet.wget("http://" .. luup.devices[lul_device].ip .. "/MainZone/index.put.asp?cmd0=PutZone_OnOff%2FON", 5)
    end
    luup.variable_set ("urn:upnp-org:serviceId:SwitchPower1", "Status", "1", lul_device)
  end
  dbVolume = math.floor(((MAX_VOLUME-MIN_VOLUME)*lul_settings.newLoadlevelTarget)/100+MIN_VOLUME)
  luup.inet.wget("http://" .. luup.devices[lul_device].ip .. "/MainZone/index.put.asp?cmd0=PutMasterVolumeSet/" .. dbVolume, 5)
end
