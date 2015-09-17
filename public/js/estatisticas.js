var labels = [];
var erros = [];
var params_bar = {
    //Boolean - Whether the scale should start at zero, or an order of magnitude down from the lowest value
    scaleBeginAtZero : true,

    //Boolean - Whether grid lines are shown across the chart
    scaleShowGridLines : true,

    //Number - Width of the grid lines
    scaleGridLineWidth : 1,

    //Boolean - Whether to show horizontal lines (except X axis)
    scaleShowHorizontalLines: true,

    //Boolean - Whether to show vertical lines (except Y axis)
    scaleShowVerticalLines: true,

    //Boolean - If there is a stroke on each bar
    barShowStroke : true,

    //Number - Pixel width of the bar stroke
    barStrokeWidth : 2,

    //Number - Spacing between each of the X value sets
    barValueSpacing : 10,

    //Number - Spacing between data sets within X values
    barDatasetSpacing : 1,

    //String - A legend template
    legendTemplate : "<div style=\"padding:15px;background-color:white;\"><% for (var i=0; i<datasets.length; i++){%><div><div style=\"display:inline-block;width:10px;height:10px;background-color:<%=datasets[i].fillColor%>\"></div> <%if(datasets[i].label){%><%=datasets[i].label%><%}%></div><%}%></div>"
}

var chartBancaAssunto = null;
var chartDisciplina = null;
var chartAssunto = null;

$(document).ready(function() {
	$.each(["banca", "ano", "orgao", "prova", "disciplina", "assunto"], function(indice, filtro) {
		$("#" + filtro).on("change", function() {
			$.ajax({
				url: "/on_change_filtro",
				type: "GET",
				dataType: "json",
				data: {
					"filtro": filtro,

					"banca": $("#banca").val(),
					"orgao": $("#orgao").val(),
					"prova": $("#prova").val(),
					"ano": $("#ano").val(),
					"disciplina": $("#disciplina").val(),
					"assunto": $("#assunto").val()
				}
			}).done( function(res) {
				if (res.filtro != "ano") $("#ano").html(res.anos);
				if (res.filtro != "orgao") $("#orgao").html(res.orgaos);
				if (res.filtro != "prova") $("#prova").html(res.provas);
				if (res.filtro != "disciplina") $("#disciplina").html(res.disciplinas);
				if (res.filtro != "banca") $("#banca").html(res.bancas);
				if (res.filtro != "assunto") $("#assunto").html(res.assuntos);
			});
		});
	});

	$.each(["banca_d", "ano_d", "orgao_d", "prova_d"], function(indice, filtro) {
		$("#" + filtro).on("change", function() {
			$.ajax({
				url: "/on_change_filtro",
				type: "GET",
				dataType: "json",
				data: {
					"filtro": filtro.replace(/_.*/g, ""),

					"banca": $("#banca_d").val(),
					"orgao": $("#orgao_d").val(),
					"ano": $("#ano_d").val(),
					"prova": $("#prova_d").val()
				}
			}).done( function(res) {
				if (res.filtro != "ano") $("#ano_d").html(res.anos);
				if (res.filtro != "orgao") $("#orgao_d").html(res.orgaos);
				if (res.filtro != "banca") $("#banca_d").html(res.bancas);
				if (res.filtro != "prova") $("#prova_d").html(res.provas);
			});
		});
	});

	$.each(["banca_a", "ano_a", "disciplina_a"], function(indice, filtro) {
		$("#" + filtro).on("change", function() {
			$.ajax({
				url: "/on_change_filtro",
				type: "GET",
				dataType: "json",
				data: {
					"filtro": filtro.replace(/_.*/g, ""),

					"banca": $("#banca_a").val(),
					"disciplina": $("#disciplina_a").val(),
					"ano": $("#ano_a").val()
				}
			}).done( function(res) {
				if (res.filtro != "ano") $("#ano_a").html(res.anos);
				if (res.filtro != "disciplina") $("#disciplina_a").html(res.disciplinas);
				if (res.filtro != "banca") $("#banca_a").html(res.bancas);
			});
		});
	});

	carregar_total_acertos_erros();
	carregar_acertos_erros_por_dia();
	carregar_questoes_resolvidas();
});


function carregar_questoes_resolvidas() {
	$.ajax({
		url: "/carregar_questoes_resolvidas",
		type: "GET",
		dataType: "json"
	}).done( function(res) {
		plotar_grafico_questoes_resolvidas(res.labels, res.questoes);
	});
}

function carregar_banca_assunto_por_ano() {
	$.ajax({
		url: "/carregar_banca_assunto_por_ano",
		type: "GET",
		dataType: "json",
		data: {
			banca: $("#banca").val(),
			disciplina: $("#disciplina").val(),
			assunto: $("#assunto").val(),
			orgao: $("#orgao").val()
		}
	}).done( function(res) {
		plotar_grafico_banca_assunto_por_ano(res.labels, res.questoes);
	});
}

function carregar_acertos_erros_por_dia() {
	$.ajax({
		url: "/carregar_acertos_erros_por_dia",
		type: "GET",
		dataType: "json"
	}).done( function(res) {
		plotar_grafico_acertos_erros_por_dia(res.labels, res.acertos, res.erros);
	});
}

function carregar_total_acertos_erros() {
	$.ajax({
		url: "/carregar_total_acertos_erros",
		type: "GET",
		dataType: "json"
	}).done( function(res) {
		plotar_grafico_total_acertos_erros(res.acertos, res.erros);
	});
}

function carregar_disciplinas() {
	$.ajax({
		url: "/carregar_disciplinas",
		type: "GET",
		dataType: "json",
		data: {
			banca_d: $("#banca_d").val(),
			ano_d: $("#ano_d").val(),
			orgao_d: $("#orgao_d").val(),
			prova_d: $("#prova_d").val()
		}
	}).done( function(res) {
		plotar_grafico_disciplinas(res.disciplinas);
	});
}

function carregar_assuntos() {
	$.ajax({
		url: "/carregar_assuntos",
		type: "GET",
		dataType: "json",
		data: {
			ano_a: $("#ano_a").val(),
			banca_a: $("#banca_a").val(),
			disciplina_a: $("#disciplina_a").val()
		}
	}).done( function(res) {
		plotar_grafico_assuntos(res.assuntos);
	});
}

function plotar_grafico_acertos_erros_por_dia(labels, acertos, erros) {
	var data = {
	    labels: labels,
	    datasets: [
	        {
	            label: "Acertos",
	            fillColor: "green",
	            strokeColor: "green",
	            highlightFill: "green",
	            highlightStroke: "green",
	            data: acertos
	        },
	        {
	            label: "Erros",
	            fillColor: "red",
	            strokeColor: "red",
	            highlightFill: "red",
	            highlightStroke: "red",
	            data: erros
	        }
	    ]
	};

	var ctx = $("#myChart").get(0).getContext("2d");
	var myBarChart = new Chart(ctx).Bar(data, params_bar);

	$("#legendDiv").html(myBarChart.generateLegend());

	var myChartHtml = $("#myChart")[0];
	var legendDivHtml = $("#legendDiv")[0];

	$("#legendDiv").css("top", myChartHtml.offsetTop + "px");
	$("#legendDiv").css("left", (myChartHtml.offsetLeft + (myChartHtml.width - $("#legendDiv").css("width").replace(/\D/g, ""))) + "px");
}

function plotar_grafico_questoes_resolvidas(labels, questoes) {
	var data = {
	    labels: labels,
	    datasets: [
	        {
	            label: "Qtde Questões",
	            fillColor: "blue",
	            strokeColor: "blue",
	            highlightFill: "blue",
	            highlightStroke: "blue",
	            data: questoes
	        }
	    ]
	};

	var ctx = $("#chartQuestoesResolvidas").get(0).getContext("2d");
	var myBarChart = new Chart(ctx).Line(data, {datasetFill : false});
}

function plotar_grafico_total_acertos_erros(acertos, erros) {
	var data = [
	    {
	        value: acertos,
	        color: "green",
	        highlight: "green",
	        label: "Acertos"
	    },
	    {
	        value: erros,
	        color: "red",
	        highlight: "red",
	        label: "Erros"
	    }
	];

	var ctx = $("#chartTotalAcertosErros").get(0).getContext("2d");
	var myBarChart = new Chart(ctx).Pie(data, {legendTemplate : "<div style=\"padding:15px;background-color:white;\"><% for (var i=0; i<segments.length; i++){%><div><div style=\"display:inline-block;width:10px;height:10px;background-color:<%=segments[i].fillColor%>\"></div> <%if(segments[i].label){%><%=segments[i].label%><%}%></div><%}%></div>"});

	$("#legendaTotalAcertosErros").html(myBarChart.generateLegend());

	var myChartHtml = $("#chartTotalAcertosErros")[0];
	var legendDivHtml = $("#legendaTotalAcertosErros")[0];

	$("#legendaTotalAcertosErros").css("top", myChartHtml.offsetTop + "px");
	$("#legendaTotalAcertosErros").css("left", (myChartHtml.offsetLeft + (myChartHtml.width - $("#legendaTotalAcertosErros").css("width").replace(/\D/g, ""))) + "px");
}

function getRandomColor() {
    var letters = '0123456789ABCDEF'.split('');
    var color = '#';
    for (var i = 0; i < 6; i++ ) {
        color += letters[Math.floor(Math.random() * 16)];
    }
    return color;
}

function plotar_grafico_disciplinas(disciplinas) {
	var data = [];
	for(var i = 0; i < disciplinas.length; i++) {
		color = getRandomColor();
		data.push(
		    {
		        value: disciplinas[i].qtde,
		        color: color,
		        highlight: color,
		        label: disciplinas[i].label
		    }
		);
	}

	var ctx = $("#chartDisciplina").get(0).getContext("2d");

	if (chartDisciplina != null) {
		chartDisciplina.destroy();
	}

	chartDisciplina = new Chart(ctx).Pie(data, {legendTemplate : "<div style=\"padding:15px;background-color:white;\"><% for (var i=0; i<segments.length; i++){%><div><div style=\"display:inline-block;width:10px;height:10px;background-color:<%=segments[i].fillColor%>\"></div> <%if(segments[i].label){%><%=segments[i].label%><%}%></div><%}%></div>"});

	$("#legendaDisciplina").html(chartDisciplina.generateLegend());

	var myChartHtml = $("#chartDisciplina")[0];
	var legendDivHtml = $("#legendaDisciplina")[0];

	$("#legendaDisciplina").css("top", myChartHtml.offsetTop + "px");
	$("#legendaDisciplina").css("left", (myChartHtml.offsetLeft + (myChartHtml.width - $("#legendaDisciplina").css("width").replace(/\D/g, ""))) + "px");
}

function plotar_grafico_assuntos(assuntos) {
	var data = [];
	for(var i = 0; i < assuntos.length; i++) {
		color = getRandomColor();
		data.push(
		    {
		        value: assuntos[i].qtde,
		        color: color,
		        highlight: color,
		        label: assuntos[i].label
		    }
		);
	}

	var ctx = $("#chartAssunto").get(0).getContext("2d");

	if (chartAssunto != null) {
		chartAssunto.destroy();
	}

	chartAssunto = new Chart(ctx).Pie(data, {legendTemplate : "<div style=\"padding:15px;background-color:white;\"><% for (var i=0; i<segments.length; i++){%><div><div style=\"display:inline-block;width:10px;height:10px;background-color:<%=segments[i].fillColor%>\"></div> <%if(segments[i].label){%><%=segments[i].label%><%}%></div><%}%></div>"});

	$("#legendaAssunto").html(chartAssunto.generateLegend());

	var myChartHtml = $("#chartAssunto")[0];
	var legendDivHtml = $("#legendaAssunto")[0];

	$("#legendaAssunto").css("top", myChartHtml.offsetTop + "px");
	$("#legendaAssunto").css("left", (myChartHtml.offsetLeft + (myChartHtml.width - $("#legendaAssunto").css("width").replace(/\D/g, ""))) + "px");
}


function plotar_grafico_banca_assunto_por_ano(labels, questoes) {
	var data = {
	    labels: labels,
	    datasets: [
	        {
	            label: "Qtde Questões",
	            fillColor: "green",
	            strokeColor: "green",
	            highlightFill: "green",
	            highlightStroke: "green",
	            data: questoes
	        }
	    ]
	};

	var ctx = $("#chartBancaAssunto").get(0).getContext("2d");
	if (chartBancaAssunto != null) {
		chartBancaAssunto.destroy();
	}
	chartBancaAssunto = new Chart(ctx).Line(data, {datasetFill : false});
}