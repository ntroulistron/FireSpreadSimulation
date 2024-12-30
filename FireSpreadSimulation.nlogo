globals [burning-history time total-burnt]

patches-own [
  state ; 0 = unburnt, 1 = burning, 2 = burnt
  cooldown ; Tracks the smoldering
  intensity ; Tracks fire intensity for burning patches
  burn-timer ; Tracks for how long a patch is burning
]

to setup ;;Setup procedure for the simulation
  clear-all
  set time 0
  set burning-history []
  set total-burnt 0
  ; Initialize the forest and empty patches
  ask patches [
    ifelse random-float 100 < tree [
      set pcolor green
      set state 0 ; Tree state
      set intensity 0
      set burn-timer 0
    ] [
      set pcolor brown
      set state -1 ; Non-flammable empty space
    ]
  ]
  ; Add rivers to avoid fire
  ask patches [
    if random-float 100 < river and pxcor != 0 and pycor != 0 [
      set pcolor blue ; River color
      set state -1 ; River patches are unburnable
    ]
  ]
  ; Start fire at the center of the forest
  ask patch 0 0 [
    set state 1
    set pcolor red
    set burn-timer 0
  ]

  if count patches with [state = 1] = 0 [
    user-message "No burning patch initialized. Please adjust tree density or setup logic."
    stop
  ]

  ; Ensure there are enough trees
  if count patches with [state = 0] = 0 [
    user-message "No trees available to burn. Please increase tree density."
    stop
  ]

  ; Add wind arrows
  setup-wind-arrows
  reset-ticks
end

to go
  wait 0.1 ; Slow down the simulation for better visualization

  ; Stop simulation if no patches are burning
  if count patches with [state = 1] = 0 [
    print (word "Simulation ended at time: " ticks)
    stop
  ]

  ; Track burning history for predictions
  set burning-history lput count patches with [state = 1] burning-history

  ; Update trees plot
  set-current-plot "Trees Available"
  set-current-plot-pen "Available Trees"
  plot count patches with [state = 0]

  set-current-plot "Trees Burnt"
  set-current-plot-pen "Trees Burnt"
  plot count patches with [state = 2]


  ; Add smoke effect
  add-smoke

  ; Highlight possible spread areas
  ask patches with [state = 1] [
    ask neighbors [
      if state = 0 [
        set pcolor orange ; Highlight possible fire spread
      ]
    ]
  ]

  ; Update smoldering and burnt patches
  ask patches with [state = 2] [
    ifelse cooldown > 0 [
      set cooldown cooldown - 1
      set pcolor gray ; Smoldering phase
    ] [
      set pcolor black ; Fully burnt
    ]
  ]

  ; Spread fire and handle intensity
  ask patches with [state = 1] [
    set burn-timer burn-timer + 1 ; Increment burn timer
    if burn-timer >= 5 and not any? neighbors with [state = 1] [
      set state 2 ; Burnt
      set pcolor black
    ]
    set intensity intensity + 1 ; Increase intensity
    if intensity > 10 [ set intensity 10 ] ; Cap intensity
    set pcolor red + intensity ; Gradual fire intensity
    set state 2 ; Transition to smoldering
    set cooldown 5 ; Smoldering time duration
    set total-burnt total-burnt + 1 ; Update total burnt area
    ask neighbors [
      let adjusted-probability fire-probability
      ; Adjust probability based on wind direction and speed
      if wind-direction = 0 [ ; North
        if pycor > [pycor] of myself [
          set adjusted-probability fire-probability * wind-speed
        ]
      ]
      if wind-direction = 1 [ ; East
        if pxcor > [pxcor] of myself [
          set adjusted-probability fire-probability * wind-speed
        ]
      ]
      if wind-direction = 2 [ ; South
        if pycor < [pycor] of myself [
          set adjusted-probability fire-probability * wind-speed
        ]
      ]
      if wind-direction = 3 [ ; West
        if pxcor < [pxcor] of myself [
          set adjusted-probability fire-probability * wind-speed
        ]
      ]
      ; Cooling effect near rivers
      if any? neighbors with [pcolor = blue] [
        set adjusted-probability adjusted-probability * 0.5
      ]
      ; Ignite unburnt neighbors based on adjusted probability
      if state = 0 and random-float 100 < adjusted-probability [
        set state 1
        set intensity 1
        set pcolor red + 1
        set burn-timer 0 ; Reset burn timer on fire spread
      ]
    ]
  ]

  ; Simulate time-based dimming
  set time time + 1
  let brightness max (list 0 (100 - time / 2))
  ask patches [
    if state = 0 [ set pcolor scale-color green brightness 0 100 ]
  ]

  ; Regrow trees
  regrow-trees

  ; Update wind arrows
  ask turtles with [shape = "arrow"] [
    set heading wind-direction * 90
  ]

  tick ; Advance the simulation time
end

to setup-wind-arrows ;;setup wind arrows procedure
  ask patches [
    if pxcor mod 5 = 0 and pycor mod 5 = 0 [ ; Place arrows
      sprout 1 [
        set shape "arrow"
        set color white
        set heading wind-direction * 90 ; Align arrows with wind direction
        set size 1
      ]
    ]
  ]
end

to add-smoke ;;add smoke procedure
  ask patches with [state = 1] [
    sprout 1 [
      set shape "circle"
      set color gray
      set size random-float 2
      set heading 90 ; Smoke moves upward
    ]
  ]
  ask turtles with [color = gray] [
    set size size - 0.1
    set ycor ycor + 0.1 ; Move upward
    if size <= 0 [ die ] ; Remove faded smoke
  ]
end

to regrow-trees ;;regrow trees procedure
  ask patches with [state = 2] [
    if random-float 100 < 5 [ ; Adjust regrowth rate as needed
      set state 0
      set pcolor green
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
915
67
1390
543
-1
-1
14.152
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

SLIDER
14
171
186
204
fire-probability
fire-probability
0
100
70.0
1
1
%
HORIZONTAL

BUTTON
148
18
211
51
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
279
18
342
51
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
431
23
823
296
Burning Trees
Time
Count
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Burning" 1.0 0 -955883 true "" "plot count patches with [state = 1]"

SLIDER
16
217
188
250
wind-direction
wind-direction
0
3
2.0
1
1
NIL
HORIZONTAL

SLIDER
16
266
188
299
wind-speed
wind-speed
1
5
3.0
1
1
NIL
HORIZONTAL

SLIDER
13
80
185
113
river
river
0
100
10.0
1
1
%
HORIZONTAL

SLIDER
14
127
186
160
tree
tree
0
100
70.0
1
1
%
HORIZONTAL

MONITOR
234
198
366
243
Burnt
count patches with [state = 2]
17
1
11

PLOT
22
312
414
597
Trees available
Time
Count
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Available Trees" 1.0 0 -13840069 true "" "plot count patches with [state = 0]"

PLOT
429
313
821
597
Trees burnt
Count
Time
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Trees Burnt" 1.0 0 -2674135 true "" "plot count patches with [state = 2]"

MONITOR
236
98
365
143
Unburnt
count patches with [state = 0]
17
1
11

@#$#@#$#@
## WHAT IS IT?

This model called FireSpreadSimulation is, displays how fire spreads in a forest. It demonstrates the role of various factors, such as tree density, wind direction and speed, and rivers, in a way that effects the fire behaviour. The model helps visualize how fire spreads over time, how some areas resist burning, and how burnt areas recover from tree regrowth.

## HOW IT WORKS

• Green Patches represent trees that can burn.
• Blue patches are rivers that block fire spread.
• Brown patches are empty ground that doesn’t burn.
• Fire spreads from burning patches with the color red to neighboring tree patches       based on: 

	1) Fire probability slider : The chance a fire spreads.

	2) Wind Direction and Speed slider : Fire spreads faster in the direction of 		  the wind.
		
	3) River proximity slider : Fire spreads slower or not at all near rivers.

• Burning patches extinguish if they don’t spread fire for 5 ticks.
• Burnt Patches with the black color can regrow into trees with the color green over     time.


## HOW TO USE IT

1) Adjust the sliders to set initial conditions:

	• tree: Adds the percentage of trees in the forest.
	• fire-probability: Sets the probability of fire spreading.
	• wind-speed: Multiplies the chance of fire spreading in the wind direction.
	• river: Controls how much of the map is covered by rivers (fire barriers).

2) Click setup to initalize the model.

3) Click Go (with the "Forever" box checked) to start the simulation.

4) Watch the fire spread on the map and track the graphs and monitors:

	• Graphs show the number of burnt, unburnt, and burning trees over time.

	• Monitors display real-time counts of burnt and unburnt trees.

## THINGS TO NOTICE

Some things you may notice once the simulation is running are :

• Fire spreads faster when trees are closer and in the direction of the wind.

• Rivers block fire spread, creating gaps in burning forest.

• Sparse forests or low fire probabilities result in slower, smaller fires.

• Burnt areas (black patches) slowly regrow into trees (green patches) over time.

• Fire extinguishes naturally if no neighboring trees are burning after 5 ticks.

• Notice how the Burnt monitor and Unburnt monitor either increases or decreases when    trees are burning or regrow.

## THINGS TO TRY

Some things you can try are : 

• Set tree to 90% and observe how dense forests cause larger fires.

• Increase fire-probability to see how quickly fire can spread in different wind         conditions.

• Test different wind-direction and wind-speed settings to observe directional fire      behavior.

• Set river to 30% to simulate a forest with many fire barriers.

• Experiment with combinations of all sliders to explore how fire behavior changes       under different conditions.

## EXTENDING THE MODEL

Some examples on how the model can be extended : 

• Add firefighter agents that actively extinguish fires in burning areas.

• Add a seasonal variation slider:

	• Dry season increases fire probability.
	• Rainy season decreases fire probability.

• Add dynamic wind that changes direction and speed over time.

• Include a firebreak tool that allows users to manually block fire spread during the    simulation.

• Create clustered forests by making tree density vary across the grid.

## NETLOGO FEATURES

Dynamic Visualization:

	• Fire intensity is shown with shades of red.

	• Smoke and wind arrows are represented by different turtle shapes (circle for 	  smoke and arrow for wind).

Randomized Behavior:
	
	• Uses random-float for probabilistic fire spread, making every run unique.

Graphs and Monitors:
	
	• Dynamic graphs track tree status (burnt, burning, unburnt) over time.

Smoldering Phase:

	• Burnt trees transition through a gray smoldering phase before becoming fully 	  burnt (black).

Interactive Settings:

	• Sliders allow users to control environmental factors like tree density, fire 	  probability, and wind.

## CREDITS AND REFERENCES

This model was developed using NetLogo (Wilensky, 1999). For further details on the functionalities and usage of NetLogo, refer to the NetLogo User Manual.

## CITATION

Wilensky, U. (1999). NetLogo. Center for Connected Learning and Computer-Based Modeling, Northwestern University. Evanston, IL. http://ccl.northwestern.edu/netlogo/
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
