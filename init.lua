-- Handle any pending lua firmware update:
if file.exists("lfs_flashed.img") then
  print("lfs_flashed.img found, removing")
  file.remove("lfs_flashed.img")
end

if file.exists("lfs_inc.img") then
  print("lfs_inc.img found; moving to lfs_flashed.img")
  file.rename("lfs_inc.img","lfs_flashed.img")
  print("flashing from lfs_flashed.img")

  wifi.setmode(wifi.NULLMODE, false)
  collectgarbage();collectgarbage()
  node.task.post( function ()
    file.remove("lfs.errormsg")
    errormsg = node.flashreload("lfs_flashed.img")
    file.open("lfs.errormsg","w")
    file.write(errormsg)
    file.close()
    node.restart()
  end)
else
  node.flashindex("_init")()
  if nil == LFS then
    print("Something went horribly wrong around LFS load!")
  end


  LFS.scaffold()
end
