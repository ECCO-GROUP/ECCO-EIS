function plot_budg(frun)
% Read Budget Tool output

global emu

% Set output directory
frun_output = fullfile(frun, 'output');

% Budget labels
fbudg = {'volume', 'heat', 'salt', 'salinity', 'momentum'};

% ---------- Read Tendency ----------
ff = fullfile(frun_output, 'emu_budg.sum_tend');
[emubudg_name, emubudg, lhs_tend, rhs_tend, adv_tend, mix_tend, frc_tend, nvar, ibud, tt] = rd_budg_sum(ff);
budg_tend = emubudg;
budg_tend_name = emubudg_name;

fprintf('*********************************************\n');
fprintf('Read sum of %s budget variables \n', fbudg{ibud});
fprintf('   budg_tend: tendency time-series (per second)\n');
fprintf('   budg_tend_name: name of variables in budg_tend\n');
fprintf('from file %s\n\n',ff);
emu.budg_tend = budg_tend;
emu.budg_tend_name = budg_tend_name;


% ---------- Read Time-Integrated ----------
ff = fullfile(frun_output, 'emu_budg.sum_tint');
[emubudg_name, emubudg, lhs_tint, rhs_tint, adv_tint, mix_tint, frc_tint, ~, ~, ~] = rd_budg_sum(ff);
budg_tint = emubudg;
budg_tint_name = emubudg_name;

fprintf('*********************************************\n');
fprintf('Read sum of %s budget variables \n', fbudg{ibud});
fprintf('   budg_tint: time-intetrated tendency time-series\n');
fprintf('   budg_tint_name: name of variables in budg_tint\n');
fprintf('from file %s\n\n',ff);
emu.budg_tint = budg_tint;
emu.budg_tint_name = budg_tint_name; 

% ---------- Read Budget Masks ----------
[budg_msk, nmsk] = rd_budg_msk(frun_output);

fprintf('*********************************************\n');
fprintf('Read 3d masks emu_budg.msk3d_* that describe the spatial location\n');
fprintf('and direction (+/- 1) of the converging fluxes budg_mkup.\n');
fprintf('   budg_msk: structure variable of the 3d masks \n');
fprintf('      budg_msk(n).msk: name (location) of mask n \n');
fprintf('      budg_msk(n).msk_dim: dimension of mask n (n3d)\n');
fprintf('      *budg_msk(n).f_msk: weights (direction) of mask n \n');
fprintf('      *budg_msk(n).i_msk: i-index of mask n \n');
fprintf('      *budg_msk(n).j_msk: j-index of mask n \n');
fprintf('      *budg_msk(n).k_msk: k-index of mask n \n');
fprintf('   budg_nmsk: number of different masks \n\n');
emu.budg_msk = budg_msk; 
emu.budg_nmsk = nmsk; 

% ---------- Read Makeup Fluxes ----------
[budg_mkup, nmkup] = rd_budg_mkup(frun_output, budg_msk);

fprintf('*********************************************\n');
fprintf('Read converging fluxes from files emu_budg.mkup_* \n');
fprintf('(budget makeup) \n');
fprintf('   budg_mkup: structure variable of the fluxes \n');
fprintf('      budg_mkup(n).var: name of flux n \n');
fprintf('      budg_mkup(n).msk: name (location) of corresponding mask \n');
fprintf('      budg_mkup(n).isum: term in emu_budg.sum_tend that this flux (n) is summed in\n');
fprintf('      budg_mkup(n).mkup_dim: spatial dimension of *budg_mkup(n).mkup \n');
fprintf('      *budg_mkup(n).mkup: flux time-series \n');
fprintf('   nmkup: number of different fluxes\n\n');
emu.budg_mkup = budg_mkup; 
emu.budg_nmkup = nmkup; 

% ---------- Set up Plotting ----------
nmonths = length(lhs_tend);
nplot = 2 + (nvar - 2) + 3;
npx = ceil(nplot / 2);
figure;
set(gcf, 'Position', [100, 100, 1200, 300 * npx]);
ip = 1;

% ---------- Plot LHS vs RHS (TEND) ----------
subplot(npx,2,ip); hold on;
plot(tt, lhs_tend, 'k', 'LineWidth', 2);
plot(tt, rhs_tend, 'r');
plot(tt, lhs_tend - rhs_tend, 'c');
legend('LHS', 'RHS', 'LHS-RHS');
title([fbudg{ibud} ' (tend)']);
ip = ip + 1;

% ---------- Plot LHS vs RHS (TINT) ----------
subplot(npx,2,ip); hold on;
plot(tt, lhs_tint, 'k', 'LineWidth', 2);
plot(tt, rhs_tint, 'r');
plot(tt, lhs_tint - rhs_tint, 'c');
legend('LHS', 'RHS', 'LHS-RHS');
title([fbudg{ibud} ' (tint)']);
ip = ip + 1;

% ---------- Plot individual terms and mkup comparison ----------
for idum = 3:nvar
    dum_ref = budg_tend(idum, :);
    dum = zeros(1, nmonths);

    subplot(npx,2,ip); hold on;
    plot(tt, dum_ref, 'k');

    % Find matching mkup terms
    imkup = find(arrayfun(@(x) x.isum == idum, [budg_mkup{:}]));

    if ~isempty(imkup)
        for ik = imkup
            for im = 1:nmonths
                dum(im) = dum(im) + sum(budg_mkup{ik}.mkup(im, :));
            end
        end
        plot(tt, dum, 'r');
        plot(tt, dum_ref - dum, 'c');
        legend('sum', 'mkup', 'sum - mkup');
    else
        legend('sum');
    end

    title([fbudg{ibud} ' ' budg_tend_name{idum}]);
    ip = ip + 1;
end

% ---------- Plot adv/mix/frc breakdown (TEND) ----------
subplot(npx,2,ip); hold on;
plot(tt, lhs_tend, 'k');
plot(tt, adv_tend, 'r');
plot(tt, mix_tend, 'c');
plot(tt, frc_tend, 'g');
legend('lhs','adv','mix','frc');
title([fbudg{ibud} ' tend']);
ip = ip + 1;

% ---------- Plot adv/mix/frc breakdown (TINT) ----------
subplot(npx,2,ip); hold on;
plot(tt, lhs_tint, 'k');
plot(tt, adv_tint, 'r');
plot(tt, mix_tint, 'c');
plot(tt, frc_tint, 'g');
legend('lhs','adv','mix','frc');
title([fbudg{ibud} ' tint']);
ip = ip + 1;

% ---------- Plot TINT with trend removed ----------
% Remove linear trend from each series
a = [ones(nmonths,1), tt(:)-mean(tt)];
inva = pinv(a);
lhs_2 = lhs_tint - (a * (inva * lhs_tint(:)))';
adv_2 = adv_tint - (a * (inva * adv_tint(:)))';
mix_2 = mix_tint - (a * (inva * mix_tint(:)))';
frc_2 = frc_tint - (a * (inva * frc_tint(:)))';

subplot(npx,2,ip); hold on;
plot(tt, lhs_2, 'k');
plot(tt, adv_2, 'r');
plot(tt, mix_2, 'c');
plot(tt, frc_2, 'g');
legend('lhs','adv','mix','frc');
title([fbudg{ibud} ' tint (trend removed)']);
ip = ip + 1;

end
