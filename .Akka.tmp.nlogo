__includes ["MouseManager.nls" "Actor.nls" "Mailbox.nls" "Task.nls" "Worker.nls" "SimpleActorImpl.nls" "FixedSizeActorImpl.nls"
  "RoutingStrategies.nls" "Scheduling.nls" "DynamicSizeActorImpl.nls" "Resizing.nls" "Observer.nls" "Controller.nls" "CollaborationObserver.nls" "CollaborationController.nls"]

globals [
  TaskA1Desc TaskB1Desc TaskC1Desc TaskD1Desc TaskE1Desc TaskA2Desc TaskB2Desc TaskC2Desc TaskD2Desc TaskE2Desc ;; Task-descriptions
  InitialWorkerListSize ;; default values
  FreeThreadsList
  CurrentObserverControllerTick
  LastEntropy
  Emergence
  CurrentEmergenceTick
]

to setup

  clear-all
  set InitialWorkerListSize 5
  set CurrentObserverControllerTick 0
  set LastEntropy -1
  set Emergence 0
  set CurrentEmergenceTick 0

  set-mouse-procedure [ [] ->
    let pos-x mouse-xcor
    let pos-y mouse-ycor
    let a new-actor pos-x pos-y "X"
  ]
  setup-actors
  setup-scheduling ThreadCount
  reset-ticks
end

to start

  scheduling-loop
  actor-loop
  worker-loop
  task-creation-loop
  ifelse ObserverControllerTrigger < CurrentObserverControllerTick [
    oberserver-loop
    controller-loop
    collaboration-observer-loop
    collaboration-controller-loop
    set CurrentObserverControllerTick 0
  ]
  [
    set CurrentObserverControllerTick CurrentObserverControllerTick + 1
  ]
  handle-emergence-calculation

  mouse-manager
  tick
end

to handle-emergence-calculation

  ifelse EmergenceInterval < CurrentEmergenceTick [
    calculate-emergence
    set CurrentEmergenceTick 0
  ]
  [
    set CurrentEmergenceTick CurrentEmergenceTick + 1
  ]
end

to calculate-emergence

  ;; calc current entropy
  let remainingTasksSum 0
  let actorsList to-list actors
  let remainingTasksList []

  foreach actorsList [ [act] ->
    ask act [
      set remainingTasksList lput remaining_tasks remainingTasksList
      set remainingTasksSum remainingTasksSum + remaining_tasks
    ]
  ]

  if remainingTasksSum = 0 [set remainingTasksSum 1]

  let probabilityList []
  foreach remainingTasksList [ [tasks] ->
    let probability tasks / remainingTasksSum
    set probabilityList lput probability probabilityList
  ]

  let entropy 0
  foreach probabilityList [ [probability] ->
    let val 0
    if probability != 0 [
      set val probability * log probability 2 ;; using log2 here for representation in bit / element
    ]

    set entropy entropy + val
  ]

  set entropy entropy * -1

  if LastEntropy != -1 [
    set Emergence LastEntropy - entropy
  ]
  set LastEntropy entropy
end

to setup-collaboration [observerList]

  let oCount length observerList

  ;; at least 3 observers are needed here
  if oCount < 3 [stop]

  let main item 0 observerList
  let l item (oCount - 1) observerList
  let r item 1 observerList

  let neighbours (list l r)
  new-collaboration-observer main neighbours

  set main l
  set r item 0 observerList
  set l item (oCount - 2) observerList
  set neighbours (list l r)
  new-collaboration-observer main neighbours

  let i 2
  loop [

    if i >= oCount [
      stop
    ]

    set r item i observerList
    set main item (i - 1) observerList
    set l item (i - 2) observerList
    set neighbours (list l r)
    new-collaboration-observer main neighbours

    set i i + 1
  ]

end

to setup-actors

  let observerList []

  ;; create the actors and for each actor a simple task with task description
  let a new-fixed-sized-actor -10 10 "A"
  let fc new-fixed-controller a
  let o new-observer a fc
  set observerList lput o observerList

  let taskList lput new-simple-task 5 []
  set TaskA1Desc new-task-description a taskList

  let b new-fixed-sized-actor 10 10 "B"
  let dc new-fixed-controller b
  set o new-observer b dc
  set observerList lput o observerList

  set taskList lput new-simple-task 10 []
  set TaskB1Desc new-task-description b taskList

  let c new-fixed-sized-actor 0 0 "C"
  set fc new-fixed-controller c
  set o new-observer c fc
  set observerList lput o observerList

  set taskList lput new-simple-task 25 []
  set TaskC1Desc new-task-description c taskList

  let d new-fixed-sized-actor -10 -10 "D"
  set dc new-fixed-controller d
  set o new-observer d dc
  set observerList lput o observerList

  set taskList lput new-simple-task 10 []
  set TaskD1Desc new-task-description d taskList

  let actE new-fixed-sized-actor 10 -10 "E"
  set fc new-fixed-controller actE
  set o new-observer actE fc
  set observerList lput o observerList

  ;; setup the collaboration oberservers now
  setup-collaboration observerList

  set taskList lput new-simple-task 5 []
  set TaskE1Desc new-task-description actE taskList

  ;; create some more complex tasks by combining the simple task descriptions
  set taskList lput new-simple-task 10 []
  let constr item 1 TaskB1Desc
  let t runresult constr
  set taskList lput t taskList
  set TaskA2Desc new-task-description a taskList

  set constr item 1 TaskA1Desc
  set taskList lput runresult constr []
  set constr item 1 TaskC1Desc
  set taskList lput runresult constr taskList
  set TaskB2Desc new-task-description b taskList

  set constr item 1 TaskD1Desc
  set taskList lput runresult constr []
  set taskList lput new-simple-task 10 taskList
  set constr item 1 TaskE1Desc
  set taskList lput runresult constr taskList
  set TaskC2Desc new-task-description c taskList

  set taskList lput new-simple-task 5 []
  set constr item 1 TaskE1Desc
  set taskList lput runresult constr taskList
  set taskList lput new-simple-task 10 taskList
  set TaskD2Desc new-task-description d taskList

  set constr item 1 TaskA1Desc
  set taskList lput runresult constr []
  set constr item 1 TaskC2Desc
  set taskList lput runresult constr taskList
  set taskList lput new-simple-task 25 taskList
  set TaskE2Desc new-task-description actE taskList

end

to task-creation-loop

  start-task TaskA1Percent TaskA1Desc
  start-task TaskB1Percent TaskB1Desc
  start-task TaskC1Percent TaskC1Desc
  start-task TaskD1Percent TaskD1Desc
  start-task TaskE1Percent TaskE1Desc

  start-task TaskA2Percent TaskA2Desc
  start-task TaskB2Percent TaskB2Desc
  start-task TaskC2Percent TaskC2Desc
  start-task TaskD2Percent TaskD2Desc
  start-task TaskE2Percent TaskE2Desc
end

to start-task [taskPercent taskDesc]

  let rand random 100

  if rand < taskPercent [
    let constr item 1 taskDesc
    let t runresult constr
    let res runresult t
  ]
end

to-report actual-worker-count-actor-e
  let actorE item 0 TaskE1Desc
  report actual-worker-count actorE
end

to-report actual-worker-count-actor-d
  let actorD item 0 TaskD1Desc
  report actual-worker-count actorD
end

to-report actual-worker-count-actor-c
  let actorC item 0 TaskC1Desc
  report actual-worker-count actorC
end

to-report actual-worker-count-actor-b
  let actorB item 0 TaskB1Desc
  report actual-worker-count actorB
end

to-report actual-worker-count-actor-a
  let actorA item 0 TaskA1Desc
  report actual-worker-count actorA
end

to-report actual-worker-count [act]
  let s 0
  ask act [
    set s actual_worker_count
  ]
  report s
end

to-report remaining-messages-actor-e
  let actorE item 0 TaskE1Desc
  report remaining-messages actorE
end

to-report remaining-messages-actor-d
  let actorD item 0 TaskD1Desc
  report remaining-messages actorD
end

to-report remaining-messages-actor-c
  let actorC item 0 TaskC1Desc
  report remaining-messages actorC
end

to-report remaining-messages-actor-b
  let actorB item 0 TaskB1Desc
  report remaining-messages actorB
end

to-report remaining-messages-actor-a
  let actorA item 0 TaskA1Desc
  report remaining-messages actorA
end

to-report remaining-messages [act]
  let s 0
  ask act [
    set s remaining_tasks
  ]
  report s
end

to-report to-turtleset [l]
  report turtle-set l
end

to-report to-list [agentset]

  let l []
  ask agentset [set l lput self l]
  report l
end
@#$#@#$#@
GRAPHICS-WINDOW
452
18
889
456
-1
-1
13.0
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

BUTTON
29
30
92
63
start
start
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
113
30
176
63
setup
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

SLIDER
902
19
1074
52
TaskA1Percent
TaskA1Percent
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
903
99
1075
132
TaskB1Percent
TaskB1Percent
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
904
171
1076
204
TaskC1Percent
TaskC1Percent
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
904
240
1076
273
TaskD1Percent
TaskD1Percent
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
903
305
1075
338
TaskE1Percent
TaskE1Percent
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
1080
19
1252
52
TaskA2Percent
TaskA2Percent
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
1081
99
1253
132
TaskB2Percent
TaskB2Percent
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
1082
172
1254
205
TaskC2Percent
TaskC2Percent
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
1083
240
1255
273
TaskD2Percent
TaskD2Percent
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
1082
305
1254
338
TaskE2Percent
TaskE2Percent
0
100
0.0
1
1
NIL
HORIZONTAL

MONITOR
1262
15
1378
60
Remaining Tasks A
remaining-messages-actor-a
17
1
11

MONITOR
1263
94
1377
139
Remeining Tasks B
remaining-messages-actor-b
17
1
11

MONITOR
1263
166
1379
211
Remaining Tasks C
remaining-messages-actor-c
17
1
11

MONITOR
1263
235
1379
280
Remaining Tasks D
remaining-messages-actor-d
17
1
11

MONITOR
1264
300
1378
345
Remaining Tasks E
remaining-messages-actor-e
17
1
11

SLIDER
199
30
371
63
ThreadCount
ThreadCount
1
100
40.0
1
1
NIL
HORIZONTAL

MONITOR
1385
15
1450
60
Worker A
actual-worker-count-actor-a
17
1
11

MONITOR
1384
94
1448
139
Worker B
actual-worker-count-actor-b
17
1
11

MONITOR
1385
166
1450
211
Worker C
actual-worker-count-actor-c
17
1
11

MONITOR
1386
235
1451
280
Worker D
actual-worker-count-actor-d
17
1
11

MONITOR
1385
300
1449
345
Worker E
actual-worker-count-actor-e
17
1
11

SLIDER
199
84
401
117
ObserverControllerTrigger
ObserverControllerTrigger
1
250
25.0
1
1
NIL
HORIZONTAL

PLOT
452
465
843
750
Emergence
Emergence
Time
0.0
10.0
-3.0
3.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot Emergence"

SLIDER
199
126
371
159
EmergenceInterval
EmergenceInterval
100
2500
1002.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
NetLogo 6.0
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
