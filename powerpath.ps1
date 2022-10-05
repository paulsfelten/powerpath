<#
	PowerShell Maze:
		A flowerpot maze game with random paths. If you make it successfully through the path without touching any bombs, you will get the 3 random users you request.
		
	Instructions: Run this script with argument "-File <file-of-names>"
	
	To Play: Use the <left>, <up>, and <right> arrow keys to navigate through the path (no going backwards!). If you hit a wall or a bomb, then you lose!
#>

param (
    $File
)

#Holds person's current position
$global:personLine;
$global:personChar;
$global:finishSpace;
$global:stopWatch;

#Prints data to the console
function Update-Screen {
	
	param (
        [System.Collections.ArrayList]$ScreenArray
    )
	
	cls;
	foreach ($line in $ScreenArray) {
		Write-Host $line
	}
}

#Picks a random column for creating path
function Random-Column {
	return Get-Random -Minimum 20 -Maximum 80
}

function Start-Screen {
	
	param (
        [System.Collections.ArrayList]$Blocks
    )
	
	#Created By
	$Blocks[2] =  "                  ||===      ===    ||   ||  ||         ||====   "
	$Blocks[3] =  "                  ||   ||  ||   ||  ||   ||  ||         ||       "
	$Blocks[4] =  "                  ||===    ||===||  ||   ||  ||         ||==     "
	$Blocks[5] =  "                  ||       ||   ||  ||   ||  ||         ||       "
	$Blocks[6] =  "                  ||       ||   ||    ===    =====      ||       "
	
	$Blocks[8] =  "   Presents: "
	
	$Blocks[10] = "        POWERPATH "
	
	$Blocks[13] = "        Script Instructions: Run this script with argument ' -File <file-of-names>'"
	
	$Blocks[16] = "        How To Play:         Use the <left>, <up>, and <right> arrow keys to navigate "
	$Blocks[17] = "                             from the bottom of the path (no going backwards!). If you"
	$Blocks[18] = "                             touch a wall or a bomb, then you lose! Only winners get 3"
	$Blocks[19] = "                             random names!                      >> Untested on Mac <<"
	
	$Blocks[25] = "                                             * = You"
	$Blocks[26] = "                                             b = Bomb"
	$Blocks[27] = "                                             $([char]0x2588) = Wall"
	
	$Blocks[40] = "                                        Press <s> to start!"
	
	Update-Screen -ScreenArray $Blocks
}

function Lose-Screen {
	
	param (
        [System.Collections.ArrayList]$Blocks
    )
	
	$Blocks[2] =  "                  ||    ||   ===    ||   ||        ||      ===     ====  ||==== "
	$Blocks[3] =  "                   ||  ||  ||   ||  ||   ||        ||    ||   || ||      ||     "
	$Blocks[4] =  "                    ||||   ||   ||  ||   ||        ||    ||   ||   ==    ||==   "
	$Blocks[5] =  "                     ||    ||   ||  ||   ||        ||    ||   ||     ||  ||     "
	$Blocks[6] =  "                     ||      ===      ===          =====   ===    ====   ||==== "
	
	Update-Screen -ScreenArray $Blocks
}

function Three-Random-Names {
	$names = [System.Collections.ArrayList]@()
	$content = Get-Content $File
	for ($i=0; $i -lt 3; $i++) {
		$name = Get-Random $content
		while ($names.IndexOf($name) -gt -1) { #prevent dupes
			$name = Get-Random $content
		}
		$names.Add($name)
	}
	return $names
}

function Win-Screen {
	
	param (
        [System.Collections.ArrayList]$Blocks
    )
	
	[System.Collections.ArrayList]$names = Three-Random-Names
	
	$names.RemoveAt(2)
	$names.RemoveAt(1)
	$names.RemoveAt(0)
	
	$Blocks[2] =  "                            ||          ||   ||   ||||  ||   ||  "
	$Blocks[3] =  "                             ||        ||    ||   || || ||   ||  "
	$Blocks[4] =  "                              ||  ||  ||     ||   ||  ||||   ||  "
	$Blocks[5] =  "                               || || ||      ||   ||    ||       "
	$Blocks[6] =  "                                ||  ||       ||   ||    ||   ==  "
	
	$Blocks[15] = "                                      RANDOM NAMES: "
	
	$Blocks[18] = "                                    1. $($names[0]) "
	$Blocks[19] = "                                    2. $($names[1]) "
	$Blocks[20] = "                                    3. $($names[2]) "
	
	Update-Screen -ScreenArray $Blocks
}

#Determine player's position
function Person-Position {
	
	param (
        [System.Collections.ArrayList]$Blocks
    )
	
	$found = 0;
	foreach ($line in $Blocks) {
		$i = $line.IndexOf('*')
		if ($i -gt 0) {
			$found = 1
			$global:personLine = $Blocks.IndexOf($line)
			$global:personChar = $i
			break
		}
	}
	if ($found -eq 0) {
			Write-Host "ERROR... PERSON NOT FOUND"
		}
}

#Create a random path
function Create-Map {
	
	param (
        [System.Collections.ArrayList]$Blocks
    )
	
	$hLines = @(0,10,20,30,40,49)
	
	#Create horizontal paths
	$spaces = ""
	for ($i=0; $i -lt 60; $i++) {
		$spaces += " "
	}
	
	for ($line=1; $line -lt $hLines.length-1; $line++) {
		$Blocks[$hLines[$line]] = $Blocks[$hLines[$line]].remove(20,60).insert(20, $spaces)
	}
	
	#Create random vertical paths
	$r = 0
	foreach ($line in $hLines) {
		if ($hLines.IndexOf($line) -ne $hLines.Length-1) {
			$r = $(Random-Column)
			
			if ($hLines.IndexOf($line) -eq 0) {
				$Blocks[$line] = $Blocks[$line].remove(0, 1).insert($r," ")
				$global:finishSpace = $r
			}
			
			for ($vert=$line+1; $vert -lt $hLines[$hLines.IndexOf($line)+1]; $vert++) {
				$Blocks[$vert] = $Blocks[$vert].remove(0, 1).insert($r," ")
			}
		}
		else { #Last row only == starting space
			$Blocks[$line] = $Blocks[$line].remove(0, 1).insert($r,"*")
			$global:personLine = $line
			$global:personChar = $r
		}
	}
	
	return $Blocks
}

#Moves the player ('*') on the screen 
function Player-Move {
	
	param (
        [System.Collections.ArrayList]$Blocks
    )
	
	$fail = 0
	$finish = 0
	$global:stopWatch = [system.diagnostics.stopwatch]::StartNew()
	
	while (($fail -eq 0) -and ($finish -eq 0)) {
		if ($global:stopWatch.elapsed.totalseconds -gt 5) {
			for ($i=0; $i -lt $Blocks.Count; $i++) {
				$Blocks[$i] = $Blocks[$i].Replace("b", " ")
			}
			
			for ($i=0; $i -lt 5; $i++) {
				$rLine = Get-Random -Minimum 0 -Maximum 49
				
				$spaces = $Blocks[$rLine].IndexOf(" ");
				$rChar = 0
				if ($spaces.Count -gt 1) {
					$rChar = Get-Random $spaces
				}
				else {
					$rChar = $spaces
				}
				
				$Blocks[$rLine] = $Blocks[$rLine].Remove($rChar, 1).Insert($rChar, "b")
			}
			
			Update-Screen -ScreenArray $Blocks
			
			$global:stopWatch = [system.diagnostics.stopwatch]::StartNew()
		}
		
		Person-Position -Blocks $Blocks
		
		$key = [System.Console]::ReadKey("NoEcho").Key.ToString()
		if ($key -eq "UpArrow"){
			if ($Blocks[$global:personLine-1].SubString($global:personChar,1) -eq " ") {
				$Blocks[$global:personLine] = $Blocks[$global:personLine].Remove($global:personChar, 1).Insert($global:personChar, " ")
				$Blocks[$global:personLine-1] = $Blocks[$global:personLine-1].Remove($global:personChar, 1).Insert($global:personChar, "*")
				$global:personLine = $global:personLine-1
			}
			else {
				$fail = 1
			}
		}
		elseif ($key -eq "RightArrow"){
			if ($Blocks[$global:personLine].SubString($global:personChar+1,1) -eq " ") {
				#replace '*' with ' '
				$Blocks[$global:personLine] = $Blocks[$global:personLine].Remove($global:personChar, 1).Insert($global:personChar, " ")
				#add '*'
				$Blocks[$global:personLine] = $Blocks[$global:personLine].Remove($global:personChar+1, 1).Insert($global:personChar+1, "*")
				$global:personChar = $global:personChar+1
			}
			else {
				$fail = 1
			}
		}
		elseif ($key -eq "LeftArrow"){
			if ($Blocks[$global:personLine].SubString($global:personChar-1,1) -eq " ") {
				#replace '*' with ' '
				$Blocks[$global:personLine] = $Blocks[$global:personLine].Remove($global:personChar, 1).Insert($global:personChar, " ")
				#add '*'
				$Blocks[$global:personLine] = $Blocks[$global:personLine].Remove($global:personChar-1, 1).Insert($global:personChar-1, "*")
				$global:personChar = $global:personChar+1
			}
			else {
				$fail = 1
			}
		}
		else {}
		
		if (($global:personLine -eq 0) -and ($global:personChar -eq $global:finishSpace)) {
			$finish = 1
		}

		if ($fail -eq 1) {
			$global:stopWatch.Stop()
			Remove-Variable $global:stopWatch
		}
		
		Update-Screen -ScreenArray $Blocks
	}
	
	if($finish -eq 1) {
		return "win"
	}
	else {
		return "lose"
	}
}

#Tunes
function Play-Music {
	[Console]::Beep(658, 125); [Console]::Beep(1320, 500);
}

#Create screen full of bricks
function Create-All-Blocks {
	$blocks = [System.Collections.ArrayList]@()
	for($i=0; $i -lt 50; $i++) {
		$tLine = [System.Collections.ArrayList]@()
		for($j=0; $j -lt 100; $j++) {
			[void]$tLine.Add($([char]0x2588))
		}
		[void]$blocks.Add(-join $tLine)
	}
	return $blocks
}

Start-Screen -Blocks $(Create-All-Blocks)

$key = [System.Console]::ReadKey("NoEcho").Key.ToString()
if ($key -eq "s"){
	[console]::beep(440,500)  
}

$map = Create-Map -Blocks $(Create-All-Blocks)
Update-Screen -ScreenArray $map

$result = Player-Move -Blocks $map

if ($result -eq "win") {
	Win-Screen -Blocks $(Create-All-Blocks)
}
else {
	Lose-Screen -Blocks $(Create-All-Blocks)
}

Play-Music