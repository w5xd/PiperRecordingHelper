# PiperRecordingHelper
perl script to aid recording for piper model creation

I use WriteLog for contesting. Phone contesting automation using recorded wav
files has been the conventional way. But WriteLog 12.93 introduced the ability to
use Piper Text-To-Speech. This repository presents an alternative way to create the
necessary recordings of your voice needed to then train a piper model suitable for
contesting.

I evaluated the https://github.com/rhasspy/piper-recording-studio for creating
the necessary .wav files to model my own voice. It works, but I found I needed to use more 
ham radio lingo in my recordings, and I simply preferred to use <a 
href='http://audacityteam.org'>Audacity</a>
to do the recording. So I wrote the PiperRecordingHelper.pl in this repo.

If you want to record the way I did, you'll need two prerequisities:
a) install http://audacityteam.org
b) install https://strawberryperl.com/

The phrases in this repository's metadata.csv came from a variety of sources. Many
are from the piper-recording-studio referenced above. Some are from collaboration with
other hams doing their own voice training. Some I computed using the PhoneticPhrases.pl
perl script here, and some I just made up thinking they would help the training.

This perl script doesn't care how you install either of its prerequisite programs, 
but in my case, in both cases above, I did not run their install msi or exe files
but instead chose their .zip versions. I just unzipped the downloadable zip and
ran audicity.exe from one and portableshell.bat from the other.

To install PiperRecordingHelper, use the "Code" button 
on https://github.com/w5xd/PiperRecordingHelper
and either git clone it or unzip it. Then run the perl script in this repo's main directory like
in this picture:

<p align='center'><img src='PiperRecordingHelper.png' alt='PiperRecordingHelper.png'/></p>

Once you satisfy the script's requirements for its command line parameters,
it will prompt you to record the first phrase. Using the recording program of your choice,
record a wav file and save it into the
same directory as the metadata.csv. The name doesn't matter except that it must end ".wav". The script
will notice it, rename it to the file named in metadata.csv and then continue to the
next phrase. Piper seems to want 48000 samples/second one-channel 16 bit signed integer .wav format
files, but I have not seen any documenation to that effect. But that format
what piper-recording-studio creates.

I used my station microphone to record.

Once recorded, I found these instructions to work for turning the recorded wav files into a piper
model:
https://ssamjh.nz/create-custom-piper-tts-voice/.
Because I used the perl script above to record my wav files, I skipped over the recording steps there 
and picked up again with the section labeled "Piper TTS" and preprocessing. Those WSL-specific
instructions are an abbreviated version of the full instructions published here:
https://github.com/rhasspy/piper/blob/master/TRAINING.md.
Per the WSL instructions from ssamjh.nz, I started with the lessac "medium" model, which reports itself
as epoch=2164. (Note: I found that the download of the checkpoint didn't work with wget.
I found that "curl -L -O my-checkpoint.ckpt <url>" did work.) Then I trained it (using my own recorded voice) to both epoch=3000 and 
epoch=4000. Even the epoch=3000 voice was, in my own opinion, quite usable for contesting,
and better than recording individual wav files as is traditionally done with WriteLog.

I had an aversion to starting the training with that lessac model, which of course it not my
own voice. It turns out that "other" voice is not a problem for the training scripts.
 This training step as documented here has no access to the original voice and
 uses only the wav files you feed it. The starting checkpoint simply lessens the
number of epochs (iterations) the training needs to converge on your voice.

It took roughly 7 elapsed hours per 1000 epochs on an Nvidia RTX-A5000 GPU. (If there ever were
a good example of a "brute force" computation, this is one. I have not studied the training
algorithm, but it looks like a case of "try everything and see what makes it sound better.)

