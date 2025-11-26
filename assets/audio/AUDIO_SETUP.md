# Audio Setup Guide

## Quick Setup

### Option 1: Download Free Horror Audio (Recommended)

**Best Sources:**
1. **Freesound.org** (https://freesound.org)
   - Search for: "horror ambient", "dark drone", "eerie atmosphere"
   - Free with attribution (CC0 or CC-BY licenses available)
   - Filter by: MP3 format, loopable, < 5MB

2. **Zapsplat.com** (https://www.zapsplat.com)
   - Free horror sound effects library
   - Requires free account
   - High quality, professional sounds

3. **OpenGameArt.org** (https://opengameart.org)
   - Free game audio assets
   - Horror-themed collections available

**Search Terms:**
- `ambient_drone.mp3`: "horror ambient", "dark drone", "eerie background"
- `clue_found.mp3`: "discovery", "success chime", "mysterious reveal"
- `jump_scare.mp3`: "jump scare", "horror sting", "scare sound"
- `heartbeat.mp3`: "heartbeat", "pulse", "thumping"
- `footsteps.mp3`: "footsteps", "walking", "creepy footsteps"
- `whispers.mp3`: "whispers", "mysterious voices", "eerie whispers"

### Option 2: Create Silent Placeholders

If you want to test without audio, you can create silent MP3 files:

```bash
# Using ffmpeg (if installed)
cd assets/audio
ffmpeg -f lavfi -i anullsrc=r=44100:cl=stereo -t 3 -q:a 9 -acodec libmp3lame ambient_drone.mp3
ffmpeg -f lavfi -i anullsrc=r=44100:cl=stereo -t 2 -q:a 9 -acodec libmp3lame clue_found.mp3
ffmpeg -f lavfi -i anullsrc=r=44100:cl=stereo -t 1 -q:a 9 -acodec libmp3lame jump_scare.mp3
ffmpeg -f lavfi -i anullsrc=r=44100:cl=stereo -t 1 -q:a 9 -acodec libmp3lame heartbeat.mp3
ffmpeg -f lavfi -i anullsrc=r=44100:cl=stereo -t 1 -q:a 9 -acodec libmp3lame footsteps.mp3
ffmpeg -f lavfi -i anullsrc=r=44100:cl=stereo -t 2 -q:a 9 -acodec libmp3lame whispers.mp3
```

### Option 3: Use AI-Generated Audio

Tools like:
- **Mubert** (https://mubert.com) - AI music generator
- **AIVA** (https://www.aiva.ai) - AI composer
- **Suno AI** - AI music generation

Generate horror-themed ambient tracks and sound effects.

## File Requirements

- **Format:** MP3
- **Sample Rate:** 44.1kHz or 48kHz
- **Bitrate:** 128-192 kbps
- **File Size:** < 5MB per file
- **Loopable:** Ambient files should loop seamlessly

## After Adding Files

1. Place all MP3 files in `assets/audio/` directory
2. Ensure filenames match exactly:
   - `ambient_drone.mp3`
   - `clue_found.mp3`
   - `jump_scare.mp3`
   - `heartbeat.mp3`
   - `footsteps.mp3`
   - `whispers.mp3`
3. Run `flutter pub get` (not required, but good practice)
4. Test the app - audio should play automatically

## Testing Audio

The audio service will:
- Play ambient drone when hunt starts (if implemented)
- Play `clue_found.mp3` when clue is discovered
- Play other sounds based on game events

Check console logs in debug mode to see if audio files are loading correctly.
