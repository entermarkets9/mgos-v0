import { useState } from 'react';
import { styled } from '@linaria/react';

const StyledContainer = styled.div`
  align-items: center;
  display: flex;
  flex: 1;
  justify-content: center;
  overflow: auto;
  padding: 24px;
`;

const StyledCalculator = styled.div`
  background: #ffffff;
  border: 1px solid #d6d6d6;
  border-radius: 8px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.12);
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 20px;
  width: 320px;
`;

const StyledTitle = styled.h2`
  color: #333333;
  font-size: 14px;
  font-weight: 600;
  margin: 0;
`;

const StyledDisplay = styled.div`
  background: #f5f5f5;
  border-radius: 6px;
  color: #111111;
  font-size: 32px;
  min-height: 56px;
  overflow-x: auto;
  padding: 8px 12px;
  text-align: right;
  white-space: nowrap;
`;

const StyledKeypad = styled.div`
  display: grid;
  gap: 8px;
  grid-template-columns: repeat(4, 1fr);
`;

const StyledKey = styled.button<{ accent?: boolean }>`
  background: ${(props) => (props.accent ? '#1961ff' : '#efefef')};
  border: none;
  border-radius: 6px;
  color: ${(props) => (props.accent ? '#ffffff' : '#111111')};
  cursor: pointer;
  font-size: 20px;
  padding: 14px 0;

  &:hover {
    filter: brightness(0.92);
  }
`;

const KEYS = [
  'C', '+/-', '%', '/',
  '7', '8', '9', '*',
  '4', '5', '6', '-',
  '1', '2', '3', '+',
  '0', '.', '=',
];

const OPERATORS = ['+', '-', '*', '/'];

const apply = (a: number, b: number, op: string): number => {
  switch (op) {
    case '+':
      return a + b;
    case '-':
      return a - b;
    case '*':
      return a * b;
    case '/':
      return b === 0 ? NaN : a / b;
    default:
      return b;
  }
};

export const CalculatorPage = () => {
  const [display, setDisplay] = useState('0');
  const [accumulator, setAccumulator] = useState<number | null>(null);
  const [operator, setOperator] = useState<string | null>(null);
  const [freshEntry, setFreshEntry] = useState(true);

  const press = (key: string) => {
    if (key === 'C') {
      setDisplay('0');
      setAccumulator(null);
      setOperator(null);
      setFreshEntry(true);
      return;
    }

    if (key === '+/-') {
      setDisplay(String(parseFloat(display) * -1));
      return;
    }

    if (key === '%') {
      setDisplay(String(parseFloat(display) / 100));
      return;
    }

    if (OPERATORS.includes(key)) {
      const current = parseFloat(display);
      const next =
        accumulator !== null && operator !== null
          ? apply(accumulator, current, operator)
          : current;

      setAccumulator(next);
      setDisplay(String(next));
      setOperator(key);
      setFreshEntry(true);
      return;
    }

    if (key === '=') {
      if (accumulator !== null && operator !== null) {
        const result = apply(accumulator, parseFloat(display), operator);
        setDisplay(Number.isNaN(result) ? 'Error' : String(result));
        setAccumulator(null);
        setOperator(null);
        setFreshEntry(true);
      }
      return;
    }

    if (freshEntry) {
      setDisplay(key === '.' ? '0.' : key);
      setFreshEntry(false);
      return;
    }

    if (key === '.' && display.includes('.')) {
      return;
    }

    setDisplay(display === '0' && key !== '.' ? key : `${display}${key}`);
  };

  return (
    <StyledContainer>
      <StyledCalculator>
        <StyledTitle>Calculator</StyledTitle>
        <StyledDisplay data-testid="calculator-display">{display}</StyledDisplay>
        <StyledKeypad>
          {KEYS.map((key) => (
            <StyledKey
              key={key}
              accent={OPERATORS.includes(key) || key === '='}
              style={key === '0' ? { gridColumn: 'span 2' } : undefined}
              onClick={() => press(key)}
            >
              {key}
            </StyledKey>
          ))}
        </StyledKeypad>
      </StyledCalculator>
    </StyledContainer>
  );
};
