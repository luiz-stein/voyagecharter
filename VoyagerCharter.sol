pragma solidity 0.5.1;

contract VoyageCharterParty {
    
    address payable afretador;
    uint public dataDePartidaPrevista;
    uint public dataDeChegadaPrevista;
    uint public dataDePartida;
    uint public dataDeChegada;
    uint public valorDoFrete;
    uint public valorTotalDosFretes;
    uint public totalDeContainers;
    uint public numeroDeContainers;
    uint public multaDiariaPorAtraso;
    uint public multaPorCancelamentoDoNavio;
    uint public multaPorCancelamentoDoFrete;
    uint public diasDeAtraso;
    uint public calculoDaMultaPorAtraso;
    
    frete [] public listaDeFretes;
    
    enum State {Fechado, Aberto, Armado, Desembarcado, Finalizado, Cancelado}
    State public state;
    
    struct frete {
        address payable walletEmbarcador;
        uint quantidadeDeContainers;
        uint valorTotalDoFrete;
        bool freteAtivo;
    }
    
    constructor(
        uint _dataDePartidaPrevista,
        uint _dataDeChegadaPrevista,
        uint _totalDeContainers,
        uint _valorDoFrete,
        uint _multaDiariaPorAtraso0a100doValorDoFrete,
        uint _multaPorCancelamentoDoNavio0a100doValorDoFrete,
        uint _multaPorCancelamentoDoFrete0a100doValorDoFrete
        ) public
    {
        afretador = msg.sender;
        dataDePartidaPrevista = _dataDePartidaPrevista;
        dataDeChegadaPrevista = _dataDeChegadaPrevista;
        totalDeContainers = _totalDeContainers;
        valorDoFrete = _valorDoFrete;
        multaDiariaPorAtraso = _multaDiariaPorAtraso0a100doValorDoFrete;
        multaPorCancelamentoDoNavio = _multaPorCancelamentoDoNavio0a100doValorDoFrete;
        multaPorCancelamentoDoFrete = _multaPorCancelamentoDoFrete0a100doValorDoFrete;
        state = State.Aberto;
    }
    
    modifier inState(State _state) {
        require(state == _state, "Invalid state.");
        _;
    }
    
    function registrarFrete(uint _quantidadeDeContainers) inState(State.Aberto) public payable {
        require(numeroDeContainers < totalDeContainers, "Embarcacao Completa.");
        require(msg.value == valorDoFrete*_quantidadeDeContainers, "Valor incorreto.");
        require(now < dataDePartidaPrevista, "Embarcacao Fechada.");
        numeroDeContainers += _quantidadeDeContainers;
        valorTotalDosFretes += msg.value;
        listaDeFretes.push(frete(msg.sender, _quantidadeDeContainers, valorDoFrete*_quantidadeDeContainers, true));
    }
    
    function cancelarViagem() inState(State.Aberto) public payable {
        require(msg.sender == afretador, "Somente o despachante pode fazer isso.");
        require(msg.value == multaPorCancelamentoDoNavio*valorDoFrete*numeroDeContainers/100);
        for (uint i=0; i<listaDeFretes.length; i++) {
            frete memory freteReembolsado = listaDeFretes[i];
            if (freteReembolsado.freteAtivo = true) {
                freteReembolsado.walletEmbarcador.transfer(address(this).balance/numeroDeContainers);
                freteReembolsado.freteAtivo = false;  
            }
        }
        state = State.Cancelado;
    }
    
    function calculoDaMultaPorCancelamentoDoFrete(uint quantidadeDeContainers) public returns (uint256) {
        return multaPorCancelamentoDoFrete*valorDoFrete*quantidadeDeContainers/100;
    }
    
    function cancelarReserva(uint identidadeDoFrete, uint quantidadeDeContainers) inState(State.Aberto) public payable {
        frete memory freteCancelado = listaDeFretes[identidadeDoFrete];
        require (msg.sender == freteCancelado.walletEmbarcador, "Somente o embarcador pode fazer isso.");
        require (freteCancelado.freteAtivo == true);
        numeroDeContainers -= 1;
        freteCancelado.walletEmbarcador.transfer((valorDoFrete*numeroDeContainers/100)*multaPorCancelamentoDoFrete);
        freteCancelado.freteAtivo = false;
    }
    
    function armarNavio() inState(State.Aberto) public {
        require(msg.sender == afretador, "Somente o afretador pode fazer isso.");
        dataDePartida = now;
        state = State.Armado;
    }
        
    function desembarcarNavio () inState(State.Armado) public {
        require(msg.sender == afretador, "Somente o afretador pode fazer isso.");
        dataDeChegada = now;
        state = State.Desembarcado;
    }
    
    function pagarViagemSemMulta() inState(State.Desembarcado) public payable {
        require(msg.sender == afretador, "Somente o armador pode fazer isso.");
        require(dataDeChegada <= dataDeChegadaPrevista, "Desembarque fora do Periodo.");
        afretador.transfer(address(this).balance);
    }
    
    function calcularDaMultaPorAtraso() public returns (uint256) {
        diasDeAtraso = dataDeChegadaPrevista-dataDeChegada/86400;
        return valorTotalDosFretes*multaDiariaPorAtraso*diasDeAtraso;
    }
    
    function navioDesembarcadoForaDoPeriodo () public payable {
        require(msg.sender == afretador, "Somente o despachante pode fazer isso.");
        require(dataDeChegada > dataDeChegadaPrevista, "Desembarque fora do Periodo.");
        require(msg.value == valorTotalDosFretes*multaDiariaPorAtraso*diasDeAtraso);
        diasDeAtraso = dataDeChegadaPrevista-dataDeChegada-dataDeChegada/86400;
        calculoDaMultaPorAtraso = multaDiariaPorAtraso*diasDeAtraso*numeroDeContainers/100;
        for (uint i=0; i<listaDeFretes.length; i++) {
            frete memory freteAtrasado = listaDeFretes[i];
            if (freteAtrasado.freteAtivo = true) {
                freteAtrasado.walletEmbarcador.transfer(multaDiariaPorAtraso*diasDeAtraso*freteAtrasado.quantidadeDeContainers/100);
                freteAtrasado.freteAtivo = false;  
            }
        }
        afretador.transfer(address(this).balance);
    }
}
