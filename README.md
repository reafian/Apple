**Apple Stuff**

Scripts I use on my Mac to do stuff.

*It's usually crap but if it works, it works :-)*

---

## Contents

This is the stuff that's in this repo.

1. music/image_resizer.sh - Small script to resize images.
2. music/renumber.sh - Small script to renumber the tracks on multi-CD albums.
3. network/wireless-restart.sh - Small script to restart the wireless network.


## image_resizer.sh

The idea is that you can throw an album image at this and it will rescale it down to 1000x1000, 600x600 and 500x500 as appropriate. I found that some music players don't like large images so rather than mess around constantly scaling some images but not others I had a script do it for me.

## renumber.sh

My network music player / twonky don't handle multi-CD albums well, they'll play CD 1 track 1 then CD 2 track 1, CD 1 track 2, CD 2 track 2 and so on, this isn't good. This script renumbers the tracks so they're fully sequential which keeps the storage / player much happier.

## wireless-restart.sh

Legacy script from the BT "Smart" Hub. When the hub restarts it overrides the IPv6 DNS servers supplied by the PiHole with it's own. It's quite frustrating. This is just a very simple command line way to jiggle the wireless adapter until I can see the correct DNS entry. (I should probably put that check in the script but as I don't need it right now it can wait.)


---