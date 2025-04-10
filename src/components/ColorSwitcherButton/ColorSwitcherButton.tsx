import './ColorSwitcherButton.scss';

const ColorSwitcherButton = ({ colorHex, currentHex, handleClick}: { colorHex: string, currentHex: string, handleClick: (colorHex: string) => void }) => {
  return (
    <a href="#" className={`colorSwitcherButton ${currentHex === colorHex ? 'active' : ''}`} onClick={() => handleClick(colorHex)}>
        <span className="spinner"></span>
        <span className="innerContent" style={{ backgroundColor: colorHex }}></span>
    </a>
  )
}

export default ColorSwitcherButton;