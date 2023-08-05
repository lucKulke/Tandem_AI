document.addEventListener('DOMContentLoaded', () => {
  const micButton = document.getElementById('micButton');
  const sendButton = document.getElementById('sendButton');
  const audioPlayback = document.getElementById('audioPlayback');

  let mediaRecorder;
  let audioChunks = [];
  let isRecording = false;

  micButton.addEventListener('click', async () => {
    if (isRecording) {
      mediaRecorder.stop();
      isRecording = false;
      micButton.classList.remove('recording');
    } else {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      mediaRecorder = new MediaRecorder(stream);

      mediaRecorder.ondataavailable = event => {
        if (event.data.size > 0) {
          audioChunks.push(event.data);
        }
      };

      mediaRecorder.onstop = () => {
        const audioBlob = new Blob(audioChunks, { type: 'audio/wav' });
        const audioUrl = URL.createObjectURL(audioBlob);

        audioPlayback.src = audioUrl;
        audioPlayback.style.display = 'block';
        audioPlayback.controls = true;
      };

      mediaRecorder.start();
      isRecording = true;
      micButton.classList.add('recording');
    }
  });

  sendButton.addEventListener('click', async () => {
    if (audioChunks.length === 0) {
      alert('No recording to send.');
      return;
    }
  
    try {
      const response = await fetch('/get_upload_url', { 
        method: 'POST',
      });
  
      if (!response.ok) {
        alert('Error getting upload URL.');
        return;
      }
  
      const data = await response.json();
      const uploadUrl = data.url;
      const filename = data.filename;
  
      const audioBlob = new Blob(audioChunks, { type: 'audio/wav' });
  
      await fetch(uploadUrl, {
        method: 'PUT',
        body: audioBlob,
        headers: {
          'Content-Disposition': `attachment; filename="${filename}"`,
          'Content-Type' : 'audio/wav'
        },
      });
  
      alert('Recording sent successfully to Amazon S3!');
    } catch (error) {
      alert('An error occurred while sending the recording.');
      console.error(error);
    }
  });
});


