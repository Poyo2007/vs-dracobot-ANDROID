function start(song) -- do nothing

end

function update (elapsed)
	if difficulty >= 1 and ((curStep >= 1800 and curStep < 1808) or (curStep >= 1824 and curStep < 1832) or (curStep >= 1840 and curStep < 1848) or (curStep >= 1864 and curStep < 1872) or (curStep >= 1880 and curStep < 1888) or (curStep >= 1896 and curStep < 1904) or (curStep >= 1928 and curStep < 1936) or (curStep >= 1952 and curStep < 1960) or (curStep >= 1968 and curStep < 1976) or (curStep >= 1992 and curStep < 2000) or (curStep >= 2008 and curStep < 2016) or (curStep >= 2024 and curStep < 2032) or (curStep >= 2056 and curStep < 2064) or (curStep >= 2080 and curStep < 2088) or (curStep >= 2096 and curStep < 2104) or (curStep >= 2120 and curStep < 2128) or (curStep >= 2136 and curStep < 2144) or (curStep >= 2152 and curStep < 2160) or (curStep >= 2184 and curStep < 2192) or (curStep >= 2208 and curStep < 2216) or (curStep >= 2224 and curStep < 2232) or (curStep >= 2248 and curStep < 2256) or (curStep >= 2264 and curStep < 2272) or (curStep >= 2280 and curStep < 2288)) then
		local currentBeat = (songPos / 1000)*(bpm/0.5)
		for i=0,7 do
			setActorX(_G['defaultStrum'..i..'X'] + 32 * math.sin((currentBeat + i*0.25) * math.pi), i)
			setActorY(_G['defaultStrum'..i..'Y'] + 32 * math.cos((currentBeat + i*0.25) * math.pi), i)
		end
	else
        	for i=0,7 do
			setActorX(_G['defaultStrum'..i..'X'],i)
			setActorY(_G['defaultStrum'..i..'Y'],i)
        	end
    	end
end

function beatHit (beat) -- do nothing

end

function stepHit (step)

end

function keyPressed (key)

end