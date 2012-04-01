-- loads a small audio file into memory (for example, a button click)

function helpers.audioLoadMemory(file)

	local handle = { handle = audio.loadSound(file), isStream = false };
	
	return handle;
	
end

-- loads an audio via streaming (for example, background music)
function helpers.audioLoadStream(file)

	local handle = { handle = audio.loadStream(file), isStream = true };
	
	return handle;
	
end

-- plays a sound
function helpers.audioPlay(handle)

	if (handle.isStream) then
		handle.channel = audio.play(handle.handle);
	else
		audio.play(handle.handle);
	end
	
end

-- pauses a sound, only for stream sounds
function helpers.audioPause(handle)

	if (handle.channel) then
		audio.pause(handle.channel);
	end
	
end

-- resumes a paused sound, only for stream sounds
function helpers.audioResume(handle)

	if (handle.channel) then
		audio.resume(handle.channel);
	end
	
end

-- stops the sound immediately
function helpers.audioStop(handle)

	if (handle.channel) then
		audio.stop(handle.channel);
		handle.channel = nil;
	end
	
	audio.rewind(handle.handle);
	
end

-- sets the volume of the audio engine (0.0 - 1.0)
function helpers.audioSetVolumne(volume)

	audio.setVolume(volume);
	
end

-- stops all audio sounds
function helpers.audioKill()

	audio.stop();
	
end

-- disposes of n audio objects
function helpers.audioDispose(...)

	for i,v in ipairs(arg) do
        audio.dispose(v.handle);
    end
	
end