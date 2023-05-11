use extendr_api::prelude::*;

/// Attribute Paths
/// @param path Character vector. Channels delimited by ">"
/// @param dates Character vector. Dates delimeted by ">"
/// @param value Numeric vector.
/// @param outcome Numeric vector.
/// @param lookup a named list of lookup values. Each element must be a scalar numeric value corresponding to a path value.
/// @export
#[extendr]
fn attr_path(
    path: Strings, dates: Strings,
    value: Doubles, outcome: Doubles,
    lookup: List) -> List {

    path
        .into_iter()
        .zip(dates.into_iter())
        .zip(value.into_iter())
        .zip(outcome.into_iter())
        .map(|(((pi, di), vi), oi)| {
            let paths = pi.split(">").collect::<Strings>();
            let dates = di.split(">").collect::<Strings>();

            let re = paths
                .iter()
                .map(|pi| {
                    Rfloat::try_from(lookup.dollar(pi).unwrap()).unwrap()
                })
                .collect::<Doubles>();

            let re_tot = re.iter().fold(0_f64, |acc, ri| {
                // handle missing values
                let ri = if ri.is_na() {
                    0_f64
                } else {
                    ri.inner()
                };

                acc + ri
            });

            let conversion = re
                .iter()
                .map(|ri| vi * ri / re_tot)
                .collect::<Doubles>();

            let value = re
                .iter()
                .map(|ri| oi * ri / re_tot)
                .collect::<Doubles>();

            list!(
                channel_name = paths,
                re = re,
                conversion = conversion,
                value = value,
                date = dates
            )
        })
    .collect::<List>()
}


extendr_module! {
    mod pathattr;
    fn attr_path;
}
