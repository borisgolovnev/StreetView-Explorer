#StreetView Explorer (Adobe Air app)
A quick and dirty implementation of the StreetView browser that allows free movement within a StreetView panorama.
Inspired and partially based on PaulWagener/Streetview-Explorer, but written in as3 for the Adobe Air runtime for a better experience across multiple platforms and more reliable XML parsing.
Allows one to move freely inside the Google StreetView images and examine the actual 3d models used.

### Controls
WASD keys for horizontal movement, + - for ascending and descending, mouse movement with left mouse button pressed to look around. Red dots are adjacent panoramas. Flying near one loads and shows it. Several panoramas are cached in memory, of which only the closest to the camera is visible.
Map button opens the map. Map click fills the coordinates form. Go button attempts to load panorama at the coordinates specified. If no panorama is found, nothing happens.

### Screenshots
<img src="http://media.tumblr.com/f6e623bef4c3cfb904a2d38af67fc2eb/tumblr_inline_mpj76s2WLo1qz4rgp.jpg" alt="some street, somewhere">
<img src="http://media.tumblr.com/4cec24975e54060dafcc72fdefdbdda9/tumblr_inline_mpj772uYUi1qz4rgp.jpg" alt="indoor panorama">

### Air package 
https://s3.amazonaws.com/bn5i3r/sve.air