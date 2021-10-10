const fetch = require('node-fetch')

const createJSONTemplate = ({ pipeline, state, gif }) => ({
  "blocks": [
    {
      "type": "section",
      "block_id": "section567",
      "text": {
        "type": "mrkdwn",
        "text": `The pipeline ${pipeline} has *${state}*`
      },
      "accessory": {
        "type": "image",
        "image_url": gif,
        "alt_text": "gif failed to load"
      }
    }
  ]
})


const apiRequest = async ({ dataToSend }) => {
  const options = {
    method: 'POST',
    body: JSON.stringify(dataToSend),
    headers: {
      'Client-Type': 'application/json',
      'Content-Length': dataToSend.length
    }
  }
  return fetch(process.env.WEBHOOK_URL, options).then(res=> res.text())
.then(res2 => console.log(`Results: ${res2}`))
.catch(err=> console.error(`Error in api call: ${err.stack}`))
}

module.exports.handler = async (event, context, callback) => {
  const {state, pipeline } = event;
  let dataToSend
  switch (state) {
    case 'STARTED':
      dataToSend = createJSONTemplate({ pipeline, state, gif: process.env.STARTED_GIF})
      break;
    case 'SUCCEEDED':
      dataToSend = createJSONTemplate({ pipeline, state, gif: process.env.SUCCEEDED_GIF})
      break;
    case 'FAILED':
      dataToSend = createJSONTemplate({ pipeline, state, gif: process.env.FAILED_GIF}) 
      break;
    case 'CANCELED':
      dataToSend = createJSONTemplate({ pipeline, state, gif: process.env.CANCELLED_GIF})
      break;
    default:
      dataToSend = createJSONTemplate({ pipeline, state, gif: ''})
      break;
  }

  return apiRequest({ dataToSend })
}
