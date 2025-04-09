import { useState } from 'react';

import ColorSwitcher from './components/ColorSwitcher';

import './App.scss'


const sCssCodeBeginning = 'background-image: url("data:image/svg+xml;charset=utf8,';
const sCssCodeEnding = '");';

/* needs to be implemented
const decodeSvg = (value: string): string => {
  let decodedValue = value;

  // add {
  decodedValue = decodedValue.replace(/%7B/g, '{');

  // add }
  decodedValue = decodedValue.replace(/%7D/g, '}');

  // add #
  decodedValue = decodedValue.replace(/%23/g, '#');

  // replace quotes
  decodedValue = decodedValue.replace(/'/g, '"');

  // replace %3C and %3E
  decodedValue = decodedValue.replace(/%3C/g, '<').replace(/%3E/g, '>');


  // add line breaks between tags
  decodedValue = decodedValue.replace(/></g, '>\n<');


  return decodedValue;
}
*/

const encodeSvg = (value: string): string => {
  let encodedValue = value;

  // remove any space between tags
  encodedValue = encodedValue.replace(/>\s+</g, '><');

  // replace < and >
  encodedValue = encodedValue.replace(/</g, '%3C').replace(/>/g, '%3E');

  // replace quotes
  encodedValue = encodedValue.replace(/"/g, '\'');

  // replace #
  encodedValue = encodedValue.replace(/#/g, '%23');

  // replace {
  encodedValue = encodedValue.replace(/\{/g, '%7B');

  // replace }
  encodedValue = encodedValue.replace(/\}/g, '%7D');

  return encodedValue;
}

const rdyForCss = (value: string): string => {

  return sCssCodeBeginning + encodeSvg(value) + sCssCodeEnding;
}

/* needs to be implemented
const removeCss = (value: string): string => {
  let raw = value;

  raw = raw.replace(sCssCodeBeginning, '');

  raw = raw.replace(sCssCodeEnding, '');

  return raw;
}
*/

function App() {
  const [previewBackgroundColor, setPreviewBackgroundColor] = useState('#fff');
  const [raw, setRaw] = useState('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" fill-rule="evenodd" stroke-linejoin="round" stroke-miterlimit="2"> <g transform="matrix(1.25305 0 0 1.25305 -16.3076 4.57191)" fill="#61dafb"> <circle cx="64" cy="47.5" r="9.3"/> <path d="M64 81.7C71.3 88.8 78.5 93 84.3 93c1.9 0 3.7-.4 5.2-1.3 5.2-3 7.1-10.5 5.3-21.2-.3-1.9-.7-3.8-1.2-5.8 2-.6 3.8-1.2 5.6-1.8 10.1-3.9 15.7-9.3 15.7-15.2 0-6-5.6-11.4-15.7-15.2-1.8-.7-3.6-1.3-5.6-1.8.5-2 .9-3.9 1.2-5.8 1.7-10.9-.2-18.5-5.4-21.5-1.5-.9-3.3-1.3-5.2-1.3-5.7 0-13 4.2-20.3 11.3C56.7 6.3 49.5 2.1 43.7 2.1c-1.9 0-3.7.4-5.2 1.3-5.2 3-7.1 10.5-5.3 21.2.3 1.9.7 3.8 1.2 5.8-2 .6-3.8 1.2-5.6 1.8-10.1 3.9-15.7 9.3-15.7 15.2 0 6 5.6 11.4 15.7 15.2 1.8.7 3.6 1.3 5.6 1.8-.5 2-.9 3.9-1.2 5.8-1.7 10.7.2 18.3 5.3 21.2 1.5.9 3.3 1.3 5.2 1.3 5.8.2 13-4 20.3-11zm-5.6-13.5c1.8.1 3.7.1 5.6.1s3.8 0 5.6-.1c-1.8 2.4-3.7 4.6-5.6 6.7-1.9-2.1-3.8-4.3-5.6-6.7zM46 57.9c1 1.7 1.9 3.3 3 4.9-3.1-.4-6-.9-8.8-1.5.9-2.7 1.9-5.5 3.1-8.3.8 1.6 1.7 3.3 2.7 4.9zm-5.8-24.1c2.8-.6 5.7-1.1 8.8-1.5l-3 4.9c-1 1.7-1.9 3.3-2.7 5a66.85 66.85 0 0 1-3.1-8.4zm5.5 13.7c1.3-2.7 2.7-5.4 4.3-8.1 1.5-2.6 3.2-5.2 4.9-7.8a136.03 136.03 0 0 1 9.1-.3 131.69 131.69 0 0 1 9.1.3c1.8 2.6 3.4 5.2 4.9 7.8 1.6 2.7 3 5.4 4.3 8.1-1.3 2.7-2.7 5.4-4.3 8.1-1.5 2.6-3.2 5.2-4.9 7.8a136.03 136.03 0 0 1-9.1.3 131.69 131.69 0 0 1-9.1-.3c-1.8-2.6-3.4-5.2-4.9-7.8-1.6-2.7-3-5.4-4.3-8.1zm39.1-5.4l-2.7-5c-1-1.7-1.9-3.3-3-4.9 3.1.4 6 .9 8.8 1.5-.9 2.8-1.9 5.6-3.1 8.4zm0 10.8c1.2 2.8 2.2 5.6 3.1 8.3-2.8.6-5.7 1.1-8.8 1.5l3-4.9c.9-1.5 1.8-3.2 2.7-4.9zm2.3 34.7c-.8.5-1.8.7-2.9.7-4.9 0-11-4-17-10 2.9-3.1 5.7-6.6 8.5-10.5 4.7-.4 9.2-1.1 13.4-2.1.5 1.8.8 3.6 1.1 5.4 1.4 8.5.3 14.6-3.1 16.5zm5.2-52.7c11.2 3.2 17.9 8.1 17.9 12.6 0 3.9-4.6 7.8-12.7 10.9-1.6.6-3.4 1.2-5.2 1.7a105.1 105.1 0 0 0-4.9-12.6c2-4.3 3.7-8.5 4.9-12.6zm-8-28.2c1.1 0 2 .2 2.9.7 3.3 1.9 4.5 7.9 3.1 16.5-.3 1.7-.7 3.5-1.1 5.4-4.2-.9-8.7-1.6-13.4-2.1-2.7-3.9-5.6-7.4-8.5-10.5 6-5.9 12.1-10 17-10zM69.6 26.8c-1.8-.1-3.7-.1-5.6-.1s-3.8 0-5.6.1c1.8-2.4 3.7-4.6 5.6-6.7 1.9 2.1 3.8 4.4 5.6 6.7zM40.9 7.4c.8-.5 1.8-.7 2.9-.7 4.9 0 11 4 17 10-2.9 3.1-5.7 6.6-8.5 10.5-4.7.4-9.2 1.1-13.4 2.1-.5-1.8-.8-3.6-1.1-5.4-1.4-8.5-.3-14.5 3.1-16.5zm-5.2 52.7C24.5 56.9 17.8 52 17.8 47.5c0-3.9 4.6-7.8 12.7-10.9 1.6-.6 3.4-1.2 5.2-1.7a105.1 105.1 0 0 0 4.9 12.6c-2 4.3-3.7 8.6-4.9 12.6zm2.1 11c.3-1.7.7-3.5 1.1-5.4 4.2.9 8.7 1.6 13.4 2.1 2.7 3.9 5.6 7.4 8.5 10.5-6 5.9-12.1 10-17 10-1.1 0-2-.2-2.9-.7-3.4-1.9-4.5-8-3.1-16.5z" fill-rule="nonzero"/> </g> </svg>');
  const [encoded, setEncoded] = useState(encodeSvg(raw));
  const [css, setCss] = useState(rdyForCss(raw));

  const handleChange = (e: React.ChangeEvent<HTMLTextAreaElement>): void => {
    setRaw(e.target.value);

    setEncoded(encodeSvg(raw));
    setCss(rdyForCss(raw));
  };

  const handleBackgroundColorChange = (colorHex: string): void => {
    setPreviewBackgroundColor(colorHex);
  }

  const handleCopy = (e: React.MouseEvent<HTMLDivElement>, value: string): void => {
    const target = e.currentTarget;

    navigator.clipboard.writeText(value);
    target.classList.add('copied');
    
    setTimeout(() => {

      target.classList.remove('copied');
    }, 400);
  }

  return (
    <main>
        <div className="areaContainer inputContainer">
          <div className="svgWrapper copy" onClick={(e) => handleCopy(e, raw)}>
            <svg viewBox="0 0 448 512" xmlns="http://www.w3.org/2000/svg"><path d="M433.941 65.941l-51.882-51.882A48 48 0 0 0 348.118 0H176c-26.51 0-48 21.49-48 48v48H48c-26.51 0-48 21.49-48 48v320c0 26.51 21.49 48 48 48h224c26.51 0 48-21.49 48-48v-48h80c26.51 0 48-21.49 48-48V99.882a48 48 0 0 0-14.059-33.941zM266 464H54a6 6 0 0 1-6-6V150a6 6 0 0 1 6-6h74v224c0 26.51 21.49 48 48 48h96v42a6 6 0 0 1-6 6zm128-96H182a6 6 0 0 1-6-6V54a6 6 0 0 1 6-6h106v88c0 13.255 10.745 24 24 24h88v202a6 6 0 0 1-6 6zm6-256h-64V48h9.632c1.591 0 3.117.632 4.243 1.757l48.368 48.368a6 6 0 0 1 1.757 4.243V112z"/></svg>
          </div>
          <textarea name="raw" id="raw" value={raw} onChange={handleChange}></textarea>
        </div>
        <div className="areaContainer inputContainer">
          <div className="svgWrapper copy" onClick={(e) => handleCopy(e, encoded)}>
            <svg viewBox="0 0 448 512" xmlns="http://www.w3.org/2000/svg"><path d="M433.941 65.941l-51.882-51.882A48 48 0 0 0 348.118 0H176c-26.51 0-48 21.49-48 48v48H48c-26.51 0-48 21.49-48 48v320c0 26.51 21.49 48 48 48h224c26.51 0 48-21.49 48-48v-48h80c26.51 0 48-21.49 48-48V99.882a48 48 0 0 0-14.059-33.941zM266 464H54a6 6 0 0 1-6-6V150a6 6 0 0 1 6-6h74v224c0 26.51 21.49 48 48 48h96v42a6 6 0 0 1-6 6zm128-96H182a6 6 0 0 1-6-6V54a6 6 0 0 1 6-6h106v88c0 13.255 10.745 24 24 24h88v202a6 6 0 0 1-6 6zm6-256h-64V48h9.632c1.591 0 3.117.632 4.243 1.757l48.368 48.368a6 6 0 0 1 1.757 4.243V112z"/></svg>
          </div>
          <textarea name="encoded" id="encoded" value={encoded}></textarea>
        </div>
        <div className="areaContainer inputContainer">
          <div className="svgWrapper copy" onClick={(e) => handleCopy(e, css)}>
            <svg viewBox="0 0 448 512" xmlns="http://www.w3.org/2000/svg"><path d="M433.941 65.941l-51.882-51.882A48 48 0 0 0 348.118 0H176c-26.51 0-48 21.49-48 48v48H48c-26.51 0-48 21.49-48 48v320c0 26.51 21.49 48 48 48h224c26.51 0 48-21.49 48-48v-48h80c26.51 0 48-21.49 48-48V99.882a48 48 0 0 0-14.059-33.941zM266 464H54a6 6 0 0 1-6-6V150a6 6 0 0 1 6-6h74v224c0 26.51 21.49 48 48 48h96v42a6 6 0 0 1-6 6zm128-96H182a6 6 0 0 1-6-6V54a6 6 0 0 1 6-6h106v88c0 13.255 10.745 24 24 24h88v202a6 6 0 0 1-6 6zm6-256h-64V48h9.632c1.591 0 3.117.632 4.243 1.757l48.368 48.368a6 6 0 0 1 1.757 4.243V112z"/></svg>
          </div>
          <textarea name="css" id="css" value={css}></textarea>
        </div>
        
        <div className="areaContainer previewContainer" style={{ backgroundColor: previewBackgroundColor }}>
          {/* TODO: store image outside and use it via import */}
          <ColorSwitcher currentBackgroundColor={previewBackgroundColor} onBackgroundColorChange={handleBackgroundColorChange} />
          {raw && <div className='svgWrapper preview' dangerouslySetInnerHTML={{ __html: raw }}></div>}
        </div>
    </main>
  )
}

export default App
