import ColorSwitcherButton from "../ColorSwitcherButton/ColorSwitcherButton";

import './ColorSwitcher.scss';

const backgroundColors = [
  '#fff',
  '#000',
  '#ccc',
];

const ColorSwitcher = ({ currentBackgroundColor, onBackgroundColorChange }: { currentBackgroundColor: string, onBackgroundColorChange: () => void }) => {
  return (
    <div className="colorSwitcher">
      {backgroundColors.map((color) => {
        return (
          <ColorSwitcherButton
            key={color}
            colorHex={color}
            currentHex={currentBackgroundColor}
            handleClick={onBackgroundColorChange}
          />
        )
      })}
    </div>
  );
};

export default ColorSwitcher;