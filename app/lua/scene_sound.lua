local scene = helpers.newScene("lua.scene_sound");

function scene:addLabel(text, y, tap)

	local lbl = helpers.newLabel
	{
		parent = self.view,
		text = text,
		fontSize = 32,
		color = { 255, 255, 255, 255 },
		x = "center",
		y = y,
		tapRelease = tap,
		tapColor = { 0, 255, 0, 255 }
	};
	
end

function scene:onCreate(event)

	self.sound1WAV = helpers.audioLoadMemory("audio/sound1.wav");
	self.sound1MP3 = helpers.audioLoadMemory("audio/sound1.mp3");
	self.music1 = helpers.audioLoadStream("audio/music1.mp3");
	
	local back = helpers.newBackButton(self.view, "images/buttons/back_button.png");
	local y = 100;
	
	self:addLabel("Play Sound1 (WAV)", y, function(event) helpers.audioPlay(self.sound1WAV); end);
	self:addLabel("Play Sound1 (MP3)", y + 50, function(event) helpers.audioPlay(self.sound1WAV); end);
	self:addLabel("Play Music", y + 100, function(event) helpers.audioPlay(self.music1); end);
	self:addLabel("Pause Music", y + 150, function(event) helpers.audioPause(self.music1); end);
	self:addLabel("Resume Music", y + 200, function(event) helpers.audioResume(self.music1); end);
	self:addLabel("Stop Music", y + 250, function(event) helpers.audioStop(self.music1); end);
	self:addLabel("Stop ALL", y + 300, function(event) helpers.audioKill(); helpers.audioStop(self.music1); end);
	
end

function scene:onDestroy()

	helpers.audioKill();
	helpers.audioDispose(self.sound1WAV, self.sound1MP3, self.music1);

end

return scene;