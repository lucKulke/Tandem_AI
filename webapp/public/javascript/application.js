$(document).ready(function() {
  const recordButton = $('#recordButton');
  const stopButton = $('#stopButton');
  const uploadButton = $('#uploadButton');
  const statusDiv = $('#status');
  const audioPlayer = $('#audioPlayer');
  
  let audioChunks = [];
  let updateInterval;
  
  const constraints = { audio: true };
  let mediaRecorder;
  
  recordButton.on('click', async () => {
    document.getElementById('user_text').textContent = '';
    document.getElementById('ai_answer').textContent = '';
    try {
      const stream = await navigator.mediaDevices.getUserMedia(constraints);
      mediaRecorder = new MediaRecorder(stream);
      
      mediaRecorder.ondataavailable = event => {
        if (event.data.size > 0) {
          audioChunks.push(event.data);
        }
      };
      
      mediaRecorder.start();
      recordButton.prop('disabled', true);
      stopButton.prop('disabled', false);
    } catch (error) {
      console.error('Error starting recording:', error);
    }
  });
  
  stopButton.on('click', () => {
    if (mediaRecorder && mediaRecorder.state === 'recording') {
      mediaRecorder.stop();
      recordButton.prop('disabled', false);
      stopButton.prop('disabled', true);
    }
  });
  
  uploadButton.on('click', async () => {
     if (audioChunks.length === 0) {
      alert('No recording to upload.');
      return;
    }
    
    try {
      const response = await fetch('/get_upload_url_for_client', {
        method: 'GET'
      });
      
      if (!response.ok) {
        alert('Error getting upload URL.');
        return;
      }
      
      const data = await response.json();
      const uploadUrl = data.url;
      const filename = data.file_name;
      console.log(uploadUrl)
      console.log(filename)
      const audioBlob = new Blob(audioChunks, { type: 'audio/wav' });
  
      
      await fetch(uploadUrl, {
        method: 'PUT',
        body: audioBlob,
        headers: {
          'Content-Type' : 'audio/wav'
          //'Content-Disposition': `attachment; filename="${filename}"`,
        },
      });
      
      alert('Recording uploaded successfully to S3!');
    } catch (error) {
      alert('An error occurred while uploading the recording.');
      console.error(error);
    }
    startUpdateLoop();
  });
  
  function startUpdateLoop() {
    updateInterval = setInterval(() => {
      fetch('/conversation/update_status')
        .then(response => response.json())
        .then(data => {
          // Update your client view with the latest data from the server
          // This could involve updating the UI, showing new messages, etc.
          
          document.getElementById('user_text').textContent = data['user_text'];
          document.getElementById('ai_answer').textContent = data['ai_answer'];
          // Check if the specific key value pair exists to stop the loop
          console.log(data)
          console.log(data['audio_file_key'])
          if (data['audio_file_key'] !== null ) {
            clearInterval(updateInterval);
            downloadAndPlayAudio(data['audio_file_key']);
          }
        })
        .catch(error => {
          console.error('Error updating conversation status:', error);
        });
    }, 5000); // Polling every 5 seconds
  }


  function downloadAndPlayAudio(audio_file_name) {
    // Initiate a GET request to download the audio file
    fetch(`/audio_files/${audio_file_name}`)
      .then(response => response.blob())
      .then(blob => {
        // Create a Blob URL for the downloaded audio file
        const audioBlobUrl = URL.createObjectURL(blob);
        
        // Play the audio
        playAudio(audioBlobUrl);
      })
      .catch(error => {
        console.error('Error downloading audio:', error);
      });
  }
  
  function playAudio(audioUrl) {
    audioPlayer.attr('src', audioUrl);
    audioPlayer.show();
    audioPlayer[0].play();
  }
});
