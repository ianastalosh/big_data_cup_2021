# Big Data Cup 2021

Thanks for coming to my Big Data Cup repo! Before starting this project, I had only watched two NHL games and each Mighty Ducks movie five or so times each. 

The final report submitted is contained in `report.pdf`. I use a k-means clustering approach to group pass types present in women's hockey. I then attempted to determine which pass types have the greatest contribution to shot attempts, be it directly or in the build up play preceding it. It didn't quite turn out how I wanted it to because I ran out of time, and I had to change my idea a few times (originally I wanted to look at passing combinations, ie. two-pass couplets, and see their effect. However, the sample size was too small and the numbers of passing combinations was too low to determine anything useful). In any case, I still think there's the pieces of an interesting idea here!

Unsurprisingly, I found passes in the offensive zone have the greatest contribution to shots, and in particular passes that land the puck near the slot. This is well known already, and have been referred to as 'high danger' passes in other papers. We also noted that stretch passes, quickly moving the puck from the defensive zone to the attacking blue line also contributed to high-ish numbers of expected goals per pass, Passes from the goal line back to the blue line also appeared to be over-represented for their value.

Below contains the data information as specified by Stathletes, who provided the data:

<h1>Dataset</h1>
<h2>Summary</h2>
<p>The dataset is comprised of Stathletes-tracked junior hockey data from the Erie Otters and women’s hockey data from the Olympics and NCAA. The included events have been translated from Stathletes’ raw data to enhance accessibility and interpretability. The various event types include shots, plays, takeaways, puck recoveries, dump ins, dump outs, zone entries, faceoffs and penalties. Event definitions may slightly differ from other sources. For each event, expanded details are provided and the relevant skaters and teams involved are indicated when necessary.</p>

<br>

<h2>Contextual Data</h2> 
<ul>
  <li>game_date (e.g. ‘2020-12-23’ == ‘yyyy-mm-dd’)</li>
  <li>season_year (e.g. 2019 == 2019-20) </li>
  <li>team_name (e.g. ‘Toronto Maple Leafs’)
    <ul><li>Name of the team responsible for the event ‘For’</li></ul>
  </li>
  <li>opp_team_name (e.g. ‘Boston Bruins’)
    <ul><li>Name of the team responsible for the event ‘Against’</li></ul>
  </li>
  <li>venue (‘home’ or ‘away’)</li>
  <li>period (e.g. 1,2,3, …)</li>
  <li>clock_seconds (time remaining in period, in seconds)</li>
  <li>situation_type (e.g. ‘5 on 5’, ‘5 on 4’, ‘4 on 5’, …)</li>
  <li>goals_for (current goals scored in a game by the eventing team)</li>
  <li>goals_against (current goals against in a game by the eventing team)</li>
  <li>player_name (name of the player responsible for the event)</li>
  <li>event (e.g. ‘Play’, ‘Shot’, ‘Zone Entry’, …)</li>
  <li>event_successful (‘t’ or ‘f’ : criteria varies by event)</li>
  <li>x_coord (x-coordinate of where an event occurred on the ice, between 0 and 200)</li>
  <li>y_coord (x-coordinate of where an event occurred on the ice, between 0 and 85)
    <ul>
      <li>(0,0) is always located in the bottom left corner of a team’s defensive zone, from the perspective of the goalie or looking ‘up ice’)</li>
      <li>Coordinates are always from the perspective of the eventing team</li>
    </ul>
  </li>
</ul>

<br>

<h2>Events</h2>
<h3>Shot</h3>
<p>Shot attempts that are unsuccessful (block, miss or save)</p>

<p>Players Involved</p>
<ul>
  <li>Player: Shooter </li>
  <li>Player 2: Passer (blank for unassisted shots)</li>
</ul>

<p>Coordinates</p>
<ul>
  <li>X,Y Coordinate: Release location </li>
</ul>

<p>Event Details</p>
<ul>
  <li>Detail 1:: Shot Type (Deflection, Fan, Slapshot, Snapshot, Wrap around, Wristshot)</li>
  <li>Detail 2: Shot destination (on net, missed or blocked)</li>
  <li>Detail 3: Traffic (true or false)</li>
  <li>Detail 4: One timer (true or false)</li>
</ul>
<br>

<h3>Goal</h3>
<p>Shot attempts that are successful (goal)</p>

<p>Players Involved</p>
<ul>
  <li>Player: Shooter </li>
  <li>Player 2: Passer (blank for unassisted shots)</li>
</ul>

<p>Coordinates</p>
<ul>
  <li>X,Y Coordinate: Release location of the puck </li>
</ul>

<p>Event Details</p>
<ul>
  <li>Detail 1:: Shot Type (Deflection, Fan, Slapshot, Snapshot, Wrap around, Wristshot)</li>
  <li>Detail 2: Shot destination (on net, missed or blocked)</li>
  <li>Detail 3: Traffic (true or false)</li>
  <li>Detail 4: One timer (true or false)</li>
</ul>
<br>



<h3>Play</h3>
<p>Pass attempts that are successful</p>

<p>Event Types</p>
<ul>
  <li>Direct (e.g. a tape-to-tape pass)</li>
  <li>Indirect (e.g. a pass that is rimmed along the boards) </li>
</ul>

<p>Players Involved</p>
<ul>
  <li>Player: Passer </li>
  <li>Player 2: Intended pass target</li>
</ul>

<p>Coordinates</p>
<ul>
  <li>X,Y Coordinate: Pass release location</li>
  <li>X,Y Coordinate: Pass target location</li>
</ul>

<p>Event details</p>
<p>Detail 1: Pass Type</p>
<ul>
  <li>Direct (eg. a tape-to-tape pass)</li>
  <li>Indirect (eg. a pass that is rimmed around the boards)</li>
</ul>
<br>

<h3>Incomplete Play</h3>
<p>Pass attempts that are unsuccessful</p>

<p>Event Types</p>
<ul>
  <li>Direct (e.g. a tape-to-tape pass)</li>
  <li>Indirect (e.g. a pass that is rimmed along the boards) </li>
</ul>

<p>Players Involved</p>
<ul>
  <li>Player: Passer </li>
  <li>Player 2: Intended pass target</li>
</ul>

<p>Coordinates</p>
<ul>
  <li>X,Y Coordinate: Pass release location</li>
  <li>X,Y Coordinate: Pass target location</li>
</ul>

<p>Event details</p>
<p>Detail 1: Pass Type</p>
<ul>
  <li>Direct (eg. a tape-to-tape pass)</li>
  <li>Indirect (eg. a pass that is rimmed around the boards)</li>
</ul>
<br>


<h3>Takeaway</h3>
<p>Steals, pass interceptions and won battles that lead to a change in possession</p>

<p>Players Involved</p>
<ul>
  <li>Player: Skater credited with the takeaway </li>
</ul>

<p>Coordinates</p>
<ul>
  <li>X,Y Coordinate: Location where the skater gained possession when taking the puck away</li>
</ul>
<br>

<h3>Puck Recovery</h3>
<p>Possession gains initiated by retrieving a loose puck that was created by a missed/blocked/saved shot, an advance (e.g. dump-out/dump-in), a faceoff or a broken play</p>

<p>Players Involved</p>
<ul>
  <li>Player: Skater who recovered the puck</li>
</ul>

<p>Coordinates</p>
<ul>
  <li>X,Y Coordinate: Location where skater gained possession</li>
</ul>
<br>
<h3>Dump In/Out</h3>
<p>Actions in which a skater intentionally concedes possession by advancing the puck up ice</p>

<p>Players Involved</p>
<ul>
  <li>Player: Skater who dumped/advanced the puck</li>
</ul>

<p>Coordinates</p>
<ul>
  <li>X,Y Coordinate: Location where skater released the puck</li>
</ul>
<p>Event details</p>
<ul>
  <li>Detail 1: Possession Outcome (Retained, Lost)</li>
</ul>

<br>
<h3>Zone Entry</h3>
<p>Attempts to move the puck into the offensive zone from the neutral zone</p>

<p>Players Involved</p>
<ul>
  <li>Player: Entry skater</li>
  <li>Player 2: Targeted defender</li>
</ul>

<p>Coordinates</p>
<ul>
  <li>X,Y Coordinate: Point of release for dumps/advances, point where puck crossed the blueline for passes and carries</li>
</ul>

<p>Event details</p>
<ul>
  <li>Detail 1: Entry Type (Carried, Dumped, Played)</li>
</ul>

<br>
<h3>Faceoff Win</h3>
<p>Faceoffs</p>

<p>Players Involved</p>
<ul>
  <li>Player:  Skater who won the draw</li>
  <li>Player 2: Skater who lost the draw</li>
</ul>

<p>Coordinates</p>
<ul>
  <li> X,Y Coordinate: Location of faceoff dot</li>
</ul>

<br>
<h3>Penalty Taken</h3>
<p>Infractions</p>


<p>Players Involved</p>
<ul>
  <li>Player: Skater who took the penalty</li>
  <li>Player 2: Skater who drew the penalty</li>
</ul>

<p>Coordinates</p>
<ul>
  <li>X,Y Coordinate: Location of infraction</li>
</ul>

<p>Event Details</p>
<ul>
  <li>Detail 1: Infraction Type (e.g. Slashing, Tripping, Roughing, Hooking, ...)</li>
</ul>

# Last Word
Once I get organised, I'll make the final report available and clean up the eda scripts. You can go through them if you'd like, but it's mostly just brainstorming and unrefined ideas.

Have a good one! 
