import './App.css';
import SwapForm from './components/SwapForm.js';
import MetaMask from './components/MetaMask.js';
import EventsFeed from './components/EventsFeed.js';
import { MetaMaskProvider } from './contexts/MetaMask';

const config = {
  token0Address: '0x700b6A60ce7EaaEA56F065753d8dcB9653dbAD35',
  token1Address: '0xA15BB66138824a1c7167f5E85b957d04Dd34E468',
  poolAddress: '0xb19b36b1456E65E3A6D514D3F715f204BD59f431',
  managerAddress: '0x8ce361602B935680E8DeC218b820ff5056BeB7af',
  ABIs: {
    'ERC20': require('./abi/ERC20.json'),
    'Pool': require('./abi/Pool.json'),
    'Manager': require('./abi/Manager.json')
  }
};

const App = () => {
  return (
    <MetaMaskProvider>
      <div className="App flex flex-col justify-between items-center w-full h-full">
        <MetaMask />
        <SwapForm config={config} />
        <footer>
          <EventsFeed config={config} />
        </footer>
      </div>
    </MetaMaskProvider>
  );
}

export default App;
