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
   
    audioChunks = [];
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
    document.getElementById('user').textContent = '';
    document.getElementById('interlocutor').textContent = '';
    //  if (audioChunks.length === 0) {
    //   alert('No recording to upload.');
    //   return;
    // }
    
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
    const historyList = document.getElementById('historyList')
    updateInterval = setInterval(() => {
      fetch('/conversation/update_status')
        .then(response => response.json())
        .then(data => {
          // Update your client view with the latest data from the server
          // This could involve updating the UI, showing new messages, etc.
          console.log(`incomming conversation text${data['section']}`);
          document.getElementById('user').textContent = data['user_text'];
          document.getElementById('interlocutor').textContent = data['ai_answer'];
          
          // Check if the specific key value pair exists to stop the loop
          console.log(data);
          console.log(data['audio_file_key']);
          if (data['audio_file_key'] !== null ) {
            let listItem = createListItem(data['section']);
            historyList.insertBefore(listItem, historyList.firstChild);
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
    fetch(`/audio_file/${audio_file_name}`)
      .then(response => response.blob())
      .then(blob => {
        // Create a Blob URL for the downloaded audio file
        const audioBlobUrl = URL.createObjectURL(blob);
        
        // Play the audio
        sendIterationEnd(audio_file_name)
        playAudio(audioBlobUrl);
      })
      .catch(error => {
        console.error('Error downloading audio:', error);
      });
  }

  function sendIterationEnd(audio_file_name){
    fetch('/iteration_end', {
      method: 'GET',
      headers: {
        'Iteration_end' : 'true'
      }
    });}
  
  function playAudio(audioUrl) {
    audioPlayer.attr('src', audioUrl);
    audioPlayer.show();
    audioPlayer[0].play();
  }

  
  function createListItem(data) {
    // Create a new list item element
    const listItem = document.createElement("li");
    listItem.classList.add("chat-item")
    // Create a div element to hold the paragraphs
    const divElement = document.createElement("div");
  
    // Create and populate the paragraphs
  
    
    const userParagraph = document.createElement("p");
    const correctorParagraph = document.createElement("p");
    const interlocutor = document.createElement("p");
    
    userParagraph.className = "user";
    correctorParagraph.className = "corrector";
    interlocutor.className = "interlocutor";
    
    userParagraph.textContent = `${data[0][0].role}: ${data[0][0].content}`;
    correctorParagraph.textContent = `(Corrector: ${data[0][1].content})`;
    interlocutor.textContent = `${data[1].role}: ${data[1].content}`;
    
    divElement.appendChild(userParagraph);
    divElement.appendChild(correctorParagraph);
    divElement.appendChild(interlocutor);
  
  
    // Append the div element to the list item
    listItem.appendChild(divElement);

    return listItem;
  }
});
